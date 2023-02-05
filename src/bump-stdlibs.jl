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
    @debug "Attempting to get upstream `julia` repo" upstream_julia_repo
    upstream_julia_repo_gh = GitHub.repo(upstream_julia_repo; config.auth)
    whoami = whoami_username(; config.auth)
    @debug("My GitHub username is: $(whoami)")
    fork_julia_repo_owner = whoami
    fork_julia_repo_name = upstream_julia_repo_name
    fork_julia_repo = "$(fork_julia_repo_owner)/$(fork_julia_repo_name)"
    fork_julia_repo_gh = create_or_get_fork(fork_julia_repo, upstream_julia_repo_gh; auth = config.auth)
    update_fork_branch(fork_julia_repo_gh, upstream_julia_repo_gh, config.julia_repo_target_branch; auth = config.auth)
    stdlib_list = get_stdlib_list(upstream_julia_repo_gh, config.julia_repo_target_branch; auth = config.auth)
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
        mktempdir() do temp_dir
            cd(temp_dir) do
                fork_clone_url = "https://x-access-token:$(config.auth.token)@github.com/$(state.fork_julia_repo_gh.full_name).git"
                run(`git clone $(fork_clone_url) FORK`)
                cd("FORK") do
                    run(`git fetch --all --prune`)
                    for (i, stdlib) in enumerate(filtered_stdlib_list)
                        predicate = generate_predicate_branch_matches_stdlib_and_target_branch(;
                            stdlib,
                            target_branch = config.julia_repo_target_branch,
                        )
                        delete_branches_with_predicate_on_origin_older_than(
                            predicate,
                            config.close_old_pull_requests_older_than;
                            exclude = state.all_pr_branches,
                        )
                    end
                end # cd("FORK")
            end # cd(temp_dir)
        end # end mktempdir()
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
    mktempdir() do temp_dir
        cd(temp_dir) do
            fork_clone_url = "https://x-access-token:$(auth.token)@github.com/$(fork_julia_repo_gh.full_name).git"
            run(`git clone $(fork_clone_url) FORK`)
            cd("FORK") do # we do this just to double-check that the `FORK` directory was created
            end
            run(`git clone $(stdlib.git_url) STDLIB`)
            cd("STDLIB") do
                run(`git checkout $(stdlib.branch)`)
                assert_current_branch_is(stdlib.branch)
                stdlib_latest_commit = strip(read(`git rev-parse HEAD`, String))
                stdlib_latest_commit_short = strip(read(`git rev-parse --short $(stdlib_latest_commit)`, String))
                assert_string_startswith(stdlib_latest_commit, stdlib_latest_commit_short)
                stdlib_current_commit_in_upstream = stdlib.current_shas["sha1"]
                stdlib_current_commit_in_upstream_short = strip(read(`git rev-parse --short $(stdlib_current_commit_in_upstream)`, String))
                assert_string_startswith(stdlib_current_commit_in_upstream, stdlib_current_commit_in_upstream_short)
                run(`git fetch --all --prune`)
                stdlib_version = if isfile("Project.toml")
                    proj = TOML.parsefile("Project.toml")
                    if haskey(proj, "version")
                        VersionNumber(proj["version"])
                    else
                        "$(stdlib.name) Project.toml has no version entry!"
                    end
                else
                    "No Project.toml found in $(stdlib.name) repo!"
                end
                changelog_cmd = `git log --oneline $(stdlib_current_commit_in_upstream_short)..$(stdlib_latest_commit_short)`
                changelog = read(changelog_cmd, String)
                if stdlib_latest_commit == stdlib_current_commit_in_upstream
                    @info "stdlib is already up to date" stdlib stdlib_latest_commit stdlib_current_commit_in_upstream
                else
                    @info "stdlib is not up to date, so I will update it now" stdlib stdlib_latest_commit stdlib_current_commit_in_upstream
                    cd(joinpath(temp_dir, "FORK")) do
                        run(`git checkout $(config.julia_repo_target_branch)`)
                        assert_current_branch_is(config.julia_repo_target_branch)
                        pr_title_without_emoji = "[$(config.julia_repo_target_branch)] Bump the $(stdlib.name) stdlib from $(stdlib_current_commit_in_upstream_short) to $(stdlib_latest_commit_short)"
                        pr_title = "🤖 $(pr_title_without_emoji)"
                        commit_message = pr_title
                        pr_branch_suffix_stripped = strip(pr_branch_suffix)
                        if isempty(pr_branch_suffix_stripped)
                            pr_branch_suffix_with_hyphen = ""
                        else
                            if !occursin(r"^[\d]*?$", pr_branch_suffix_stripped)
                                msg = "Suffix must only be numerical: $(pr_branch_suffix_stripped)"
                                throw(ErrorException(msg))
                            end
                            pr_branch_suffix_with_hyphen = "-$(pr_branch_suffix_stripped)"
                        end
                        pr_branch = "BumpStdlibs$(pr_branch_suffix_with_hyphen)/$(stdlib.name)-$(stdlib_latest_commit_short)-$(config.julia_repo_target_branch)"
                        push!(state.all_pr_branches, pr_branch)
                        git_url_markdown = _git_url_to_formatted_markdown(stdlib.git_url)
                        bumpstdlibs_sender = strip(get(ENV, "BUMPSTDLIBS_SENDER", ""))
                        bumpstdlibs_sender_ping = isempty(bumpstdlibs_sender) ? "unknown user" : "@$(bumpstdlibs_sender)"
                        julia_version = Base.VersionNumber(read("VERSION", String))
                        version_match = stdlib_version isa VersionNumber && Base.thispatch(julia_version) === Base.thispatch(stdlib_version)
                        url_for_diff = chopsuffix(git_url_markdown, ".git")
                        pr_body_lines = String[
                            "Stdlib: $(stdlib.name)",
                            "URL: $(git_url_markdown)",
                            "Stdlib branch: $(stdlib.branch)",
                            "Julia branch: $(config.julia_repo_target_branch)",
                            "Old commit: $(stdlib_current_commit_in_upstream_short)",
                            "New commit: $(stdlib_latest_commit_short)",
                            "Julia version: $(julia_version)",
                            "$(stdlib.name) version: $(stdlib_version)$(version_match ? "" : " (Does not match)")",
                            "Bump invoked by: $(bumpstdlibs_sender_ping)",
                            "Powered by: [BumpStdlibs.jl](https://github.com/JuliaLang/BumpStdlibs.jl)",
                            "",
                            "Diff: $(url_for_diff)/compare/$(stdlib_current_commit_in_upstream)...$(stdlib_latest_commit)",
                            "",
                            "```",
                            "\$ $(strip(string(changelog_cmd), '`'))",
                            changelog,
                            "```",
                        ]
                        pr_body = strip(join(strip.(pr_body_lines), "\n"))
                        run(`git checkout -B $(pr_branch)`)
                        assert_current_branch_is(pr_branch)
                        version_filename = joinpath("stdlib", "$(stdlib.name).version")
                        old_version_contents = strip(read(version_filename, String))
                        new_version_contents = replace(old_version_contents, stdlib_current_commit_in_upstream => stdlib_latest_commit)
                        rm(version_filename; force = true, recursive = true)
                        open(version_filename, "w") do io
                            println(io, new_version_contents)
                        end
                        assert_file_contains(version_filename, stdlib_latest_commit)
                        for (root, dirs, files) in walkdir(joinpath(pwd(), "deps", "checksums"))
                            for file in files
                                full_path = joinpath(root, file)
                                startswith(strip(file), "$(stdlib.name)-") && ispath(full_path) && rm(full_path; force = true, recursive = true)
                            end
                        end
                        directories_to_delete = String[]
                        for (root, dirs, files) in walkdir(joinpath(pwd(), "deps", "checksums"))
                            for dir in dirs
                                full_path = joinpath(root, dir)
                                if startswith(strip(dir), "$(stdlib.name)-")
                                    @debug "" root dir full_path
                                    if isdir(full_path)
                                        push!(directories_to_delete, full_path)
                                    end
                                end
                            end
                        end
                        for full_path in directories_to_delete
                            @debug "" full_path
                            if isdir(full_path)
                                rm(full_path; force = true, recursive = true)
                            end
                        end
                        checksum_files_that_need_refreshing = String[]
                        for (root, dirs, files) in walkdir(joinpath(pwd(), "deps", "checksums"))
                            for file in files
                                full_path = joinpath(root, file)
                                contains_matching_lines = delete_checksum_lines(;
                                    checksum_file = full_path,
                                    stdlib_name = stdlib.name,
                                )
                                if contains_matching_lines
                                    push!(checksum_files_that_need_refreshing, file)
                                end
                            end
                        end
                        cd("stdlib") do
                            run(`make`)
                        end
                        file_to_target = Dict(
                            "suitesparse" => "libsuitesparse",
                        )
                        for file in checksum_files_that_need_refreshing
                            if haskey(file_to_target, file)
                                target = file_to_target[file]
                            else
                                target = file
                            end
                            run(`make -f contrib/refresh_checksums.mk $(target)`)
                        end
                        run(`git add -A`)
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
                        whoami = whoami_username(; config.auth)
                        pr_head_with_fork_owner = "$(whoami):$(pr_branch)"
                        pr_state = Dict{String, Any}(
                            "base" => config.julia_repo_target_branch,
                            "body" => strip(pr_body),
                            "head" => pr_head_with_fork_owner,
                            "maintainer_can_modify" => true,
                            "title" => pr_title,
                        )
                        @debug "" pr_body
                        @debug "" upstream_julia_repo_gh.full_name
                        @debug "" fork_julia_repo_gh.full_name
                        @debug "" pr_state
                        pr = create_or_update_pull_request(upstream_julia_repo_gh, pr_state; auth = config.auth)
                    end # cd(joinpath(temp_dir, "FORK"))
                end # if
            end # cd("STDLIB"
        end # cd(temp_dir)
    end # mktempdir()
    return nothing
end
