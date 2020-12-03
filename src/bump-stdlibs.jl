"""
    bump_stdlibs(julia_repo; kwargs...)
"""
function bump_stdlibs(julia_repo::AbstractString; kwargs...)
    config = Config(; kwargs...)
    bump_stdlibs(julia_repo, config)
    return nothing
end

function bump_stdlibs(julia_repo::AbstractString, config::Config)
    repo_regex = r"^([\w\-\_]*?)\/([\w]*?)$"
    if !occursin(repo_regex, julia_repo)
        msg = "Invalid value for julia_repo: \"$(julia_repo)\". julia_repo must be of the form owner/repo. For example: julia_repo=\"JuliaLang/julia\""
        throw(ArgumentError(msg))
    end
    m = match(repo_regex, julia_repo)
    upstream_julia_repo_owner = m[1]
    upstream_julia_repo_name = m[2]
    upstream_julia_repo = "$(upstream_julia_repo_owner)/$(upstream_julia_repo_name)"
    upstream_julia_repo_gh = GitHub.repo(upstream_julia_repo; auth = config.auth)
    whoami = GitHub.whoami(; auth = config.auth).login
    @debug("My GitHub username is: $(whoami)")
    fork_julia_repo_owner = whoami
    fork_julia_repo_name = upstream_julia_repo_name
    fork_julia_repo = "$(fork_julia_repo_owner)/$(fork_julia_repo_name)"
    fork_julia_repo_gh = create_or_get_fork(fork_julia_repo, upstream_julia_repo_gh; auth = config.auth)
    if config.julia_repo_default_branch isa Nothing
        upstream_julia_repo_default_branch = convert(String, upstream_julia_repo_gh.default_branch)::String
    else
        upstream_julia_repo_default_branch = convert(String, config.julia_repo_default_branch)::String
    end
    update_fork_branch(fork_julia_repo_gh, upstream_julia_repo_gh, upstream_julia_repo_gh.default_branch; auth = config.auth)
    stdlib_list = get_stdlib_list(upstream_julia_repo_gh, upstream_julia_repo_gh.default_branch; auth = config.auth)
    @info "Identified $(length(stdlib_list)) stdlibs that live in external repositories"
    for (i, stdlib) in enumerate(stdlib_list)
        @info "" i stdlib
    end
    filtered_stdlib_list = filter_stdlib_list(stdlib_list, config.stdlibs_to_include)
    @info "Based on the input criteria \"$(config.stdlibs_to_include)\", we will try to update $(length(filtered_stdlib_list)) stdlibs"
    for (i, stdlib) in enumerate(filtered_stdlib_list)
        @info "" i stdlib
    end
    errors = Any[]
    all_pr_branches = String[]
    state = State(;
        fork_julia_repo_gh = fork_julia_repo_gh,
        upstream_julia_repo_default_branch = upstream_julia_repo_default_branch,
        upstream_julia_repo_gh = upstream_julia_repo_gh,
    )
    for (i, stdlib) in enumerate(filtered_stdlib_list)
        @info "Starting to work on" i stdlib length(filtered_stdlib_list)
        try
            _bump_single_stdlib(stdlib, config, state)
            @info "Successfully finished working on" i stdlib length(filtered_stdlib_list)
        catch ex
            push!(errors, ex)
            @error "Encountered an error while working on" exception=(ex, catch_backtrace()) i stdlib length(filtered_stdlib_list)
        end
    end
    if config.close_old_pull_requests
        with_temp_dir() do temp_dir
            cd(temp_dir)
            fork_clone_url = "https://x-access-token:$(config.auth.token)@github.com/$(state.fork_julia_repo_gh.full_name).git"
            run(`git clone $(fork_clone_url) FORK`)
            cd("FORK")
            run(`git fetch --all --prune`)
            for (i, stdlib) in enumerate(filtered_stdlib_list)
                prefix = "BumpStdlibs/$(stdlib.name)-"
                delete_branches_with_prefix_on_origin_older_than(
                    prefix,
                    config.close_old_pull_requests_older_than;
                    exclude = state.all_pr_branches,
                )
            end
        end
    end
    if !isempty(errors)
        @error "Encountered at least one error" errors
        throw(ErrorException("Encountered at least one error"))
    end
    return nothing
end

function _bump_single_stdlib(stdlib::StdlibInfo, config::Config, state::State)
    auth = config.auth
    pr_branch_suffix = config.pr_branch_suffix
    fork_julia_repo_gh = state.fork_julia_repo_gh
    upstream_julia_repo_gh = state.upstream_julia_repo_gh
    upstream_julia_repo_default_branch = state.upstream_julia_repo_default_branch
    with_temp_dir() do temp_dir
        cd(temp_dir)
        name = stdlib.name
        token = auth.token
        fork_clone_url = "https://x-access-token:$(token)@github.com/$(fork_julia_repo_gh.full_name).git"
        run(`git clone $(fork_clone_url) FORK`)
        cd("FORK")
        cd(temp_dir)
        stdlib_clone_url = stdlib.git_url
        run(`git clone $(stdlib_clone_url) STDLIB`)
        cd("STDLIB")
        run(`git checkout $(stdlib.branch)`)
        assert_current_branch_is(stdlib.branch)
        stdlib_latest_commit = strip(read(`git rev-parse HEAD`, String))
        stdlib_latest_commit_short = strip(read(`git rev-parse --short $(stdlib_latest_commit)`, String))
        assert_string_startswith(stdlib_latest_commit, stdlib_latest_commit_short)
        stdlib_current_commit_in_upstream = stdlib.current_shas["sha1"]
        stdlib_current_commit_in_upstream_short = strip(read(`git rev-parse --short $(stdlib_current_commit_in_upstream)`, String))
        assert_string_startswith(stdlib_current_commit_in_upstream, stdlib_current_commit_in_upstream_short)
        if stdlib_latest_commit == stdlib_current_commit_in_upstream
            @info "stdlib is already up to date" stdlib stdlib_latest_commit stdlib_current_commit_in_upstream
        else
            @info "stdlib is not up to date, so I will update it now" stdlib stdlib_latest_commit stdlib_current_commit_in_upstream
            cd(temp_dir)
            cd("STDLIB")
            run(`git fetch --all --prune`)
            changelog_cmd = `git log --oneline $(stdlib_current_commit_in_upstream_short)..$(stdlib_latest_commit_short)`
            changelog = read(changelog_cmd, String)
            cd(temp_dir)
            cd("FORK")
            run(`git checkout $(upstream_julia_repo_default_branch)`)
            assert_current_branch_is(upstream_julia_repo_default_branch)
            pr_title_without_emoji = "Bump the $(name) stdlib from $(stdlib_current_commit_in_upstream_short) to $(stdlib_latest_commit_short)"
            pr_title = "🤖 $(pr_title_without_emoji)"
            commit_message = "[automated] $(pr_title_without_emoji)"
            pr_branch_suffix_stripped = strip(pr_branch_suffix)
            if isempty(pr_branch_suffix_stripped)
                pr_branch_suffix_with_hyphen = ""
            else
                pr_branch_suffix_with_hyphen = "-$(pr_branch_suffix_stripped)"
            end
            pr_branch = "BumpStdlibs/$(name)-$(stdlib_latest_commit_short)$(pr_branch_suffix_with_hyphen)"
            push!(state.all_pr_branches, pr_branch)
            pr_body_lines = String[
                "Stdlib: $(name)",
                "Branch: $(stdlib.branch)",
                "Old commit: $(stdlib_current_commit_in_upstream_short)",
                "New commit: $(stdlib_latest_commit_short)",
                "",
                "```",
                strip(string(changelog_cmd), '`'),
                changelog,
                "```",
            ]
            pr_body = strip(join(strip.(pr_body_lines), "\n"))
            run(`git checkout -B $(pr_branch)`)
            assert_current_branch_is(pr_branch)
            version_filename = joinpath("stdlib", "$(name).version")
            old_version_contents = strip(read(version_filename, String))
            new_version_contents = replace(old_version_contents, stdlib_current_commit_in_upstream => stdlib_latest_commit)
            rm(version_filename; force = true, recursive = true)
            open(version_filename, "w") do io
                println(io, new_version_contents)
            end
            assert_file_contains(version_filename, stdlib_latest_commit)
            run(`bash -c "git rm -rf deps/checksums/$(name)-*"`)
            cd("stdlib")
            run(`make`)
            cd(temp_dir)
            cd("FORK")
            run(`git add stdlib/$(name).version`)
            run(`bash -c "git add deps/checksums/$(name)-*"`)
            run(`git commit -m "$(commit_message)"`)
            do_push = true
            if !(config.push_if_no_changes)
                if pr_branch in get_origin_branches()
                    if git_diff_is_empty("HEAD", "origin/$(pr_branch)")
                        do_push = false
                    end
                end
            end
            @info "" do_push
            if do_push
                run(`git push --force origin $(pr_branch)`)
            end
            whoami = GitHub.whoami(; auth = config.auth).login
            pr_head_with_fork_owner = "$(whoami):$(pr_branch)"
            pr_state = Dict{String, Any}(
                "base" => upstream_julia_repo_default_branch,
                "body" => strip(pr_body),
                "head" => pr_head_with_fork_owner,
                "maintainer_can_modify" => true,
                "title" => pr_title,
            )
            @debug "" upstream_julia_repo_gh
            @debug "" fork_julia_repo_gh
            @debug "" pr_state
            pr = create_or_update_pull_request(upstream_julia_repo_gh, pr_state; auth = config.auth)
        end
        return nothing
    end
    return nothing
end
