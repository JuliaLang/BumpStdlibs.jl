"""
    bump_stdlibs(julia_repo;
                auth = get_auth_from_environment(),
                julia_repo_default_branch::Union{AbstractString, Nothing} = nothing,
                pr_title_suffix::AbstractString = "",
                pr_branch_suffix::AbstractString = "",
                stdlibs_to_include::Union{AbstractString, AbstractVector{<:AbstractString}} = get_stdlibs_to_include_from_environment())
"""
function bump_stdlibs(julia_repo;
                      auth = get_auth_from_environment(),
                      julia_repo_default_branch::Union{AbstractString, Nothing} = nothing,
                      pr_title_suffix::AbstractString = "",
                      pr_branch_suffix::AbstractString = "",
                      stdlibs_to_include::Union{AbstractString, AbstractVector{<:AbstractString}} = get_stdlibs_to_include_from_environment())
    repo_regex = r"^([\w\-\_]*?)\/([\w]*?)$"
    if !occursin(repo_regex, julia_repo)
        msg = "Invalid value for julia_repo: \"$(julia_repo)\". julia_repo must be of the form owner/repo. For example: julia_repo=\"JuliaLang/julia\""
        throw(ArgumentError(msg))
    end
    m = match(repo_regex, julia_repo)
    upstream_julia_repo_owner = m[1]
    upstream_julia_repo_name = m[2]
    upstream_julia_repo = "$(upstream_julia_repo_owner)/$(upstream_julia_repo_name)"
    upstream_julia_repo_gh = GitHub.repo(upstream_julia_repo; auth = auth)
    whoami = GitHub.whoami(; auth = auth).login
    @debug("My GitHub username is: $(whoami)")
    fork_julia_repo_owner = whoami
    fork_julia_repo_name = upstream_julia_repo_name
    fork_julia_repo = "$(fork_julia_repo_owner)/$(fork_julia_repo_name)"
    fork_julia_repo_gh = create_or_get_fork(fork_julia_repo, upstream_julia_repo_gh; auth = auth)
    if julia_repo_default_branch isa Nothing
        upstream_julia_repo_default_branch = convert(String, upstream_julia_repo_gh.default_branch)::String
    else
        upstream_julia_repo_default_branch = convert(String, julia_repo_default_branch)::String
    end
    update_fork_branch(fork_julia_repo_gh, upstream_julia_repo_gh, upstream_julia_repo_gh.default_branch; auth = auth)
    stdlib_list = get_stdlib_list(upstream_julia_repo_gh, upstream_julia_repo_gh.default_branch; auth = auth)
    @info "Identified $(length(stdlib_list)) stdlibs that live in external repositories"
    for (i, stdlib) in enumerate(stdlib_list)
        @info "" i stdlib
    end
    filtered_stdlib_list = filter_stdlib_list(stdlib_list, stdlibs_to_include)
    @info "Based on the input criteria \"$(stdlibs_to_include)\", we will try to update $(length(filtered_stdlib_list)) stdlibs"
    for (i, stdlib) in enumerate(filtered_stdlib_list)
        @info "" i stdlib
    end
    for (i, stdlib) in enumerate(filtered_stdlib_list)
        @info "Starting to work on" i stdlib length(filtered_stdlib_list)
        _bump_single_stdlib(
            stdlib;
            auth,
            fork_julia_repo_gh,
            pr_title_suffix,
            pr_branch_suffix,
            upstream_julia_repo_default_branch,
            upstream_julia_repo_gh,
        )
        @info "Finished working on" i stdlib length(filtered_stdlib_list)
    end
    return nothing
end

function _bump_single_stdlib(stdlib::StdlibInfo;
                             auth,
                             fork_julia_repo_gh,
                             pr_title_suffix,
                             pr_branch_suffix,
                             upstream_julia_repo_default_branch,
                             upstream_julia_repo_gh)
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
        stdlib_latest_commit_short = strip(read(`git rev-parse --short HEAD`, String))
        stdlib_current_commit_in_upstream = stdlib.current_shas["sha1"]
        if stdlib_latest_commit == stdlib_current_commit_in_upstream
            @info "stdlib is already up to date" stdlib stdlib_latest_commit stdlib_current_commit_in_upstream
        else
            @info "stdlib is not up to date, so I will update it now" stdlib stdlib_latest_commit stdlib_current_commit_in_upstream
            cd(temp_dir)
            cd("STDLIB")
            run(`git fetch --all --prune`)
            changelog = read(`git log --pretty=oneline --abbrev=commit $(stdlib_current_commit_in_upstream)^..$(stdlib_latest_commit)`, String)
            cd(temp_dir)
            cd("FORK")
            run(`git checkout $(upstream_julia_repo_default_branch)`)
            assert_current_branch_is(upstream_julia_repo_default_branch)
            pr_title = "[automated] Bump the $(name) stdlib to $(stdlib_latest_commit_short)$(pr_title_suffix)"
            pr_title_long = "[automated] Bump the $(name) stdlib to $(stdlib_latest_commit)$(pr_title_suffix)"
            pr_branch = "bump_stdlibs/bump-$(name)-to-$(stdlib_latest_commit)$(pr_branch_suffix)"
            pr_body = string(
                "```\n",
                "\$ git log --pretty=oneline --abbrev=commit $(stdlib_current_commit_in_upstream)^..$(stdlib_latest_commit)\n",
                "$(strip(changelog))\n",
                "```\n",
            )
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
            run(`git commit -m "$(pr_title_long)"`)
            run(`git push -f origin $(pr_branch)`)
            whoami = GitHub.whoami(; auth = auth).login
            pr_head_with_fork_owner = "$(whoami):$(pr_branch)"
            pr_params = Dict{String, Any}(
                "base" => upstream_julia_repo_default_branch,
                "body" => strip(pr_body),
                "head" => pr_head_with_fork_owner,
                "maintainer_can_modify" => true,
                "title" => pr_title,
            )
            @debug "" upstream_julia_repo_gh
            @debug "" fork_julia_repo_gh
            @debug "" pr_params
            pr = create_or_update_pull_request(upstream_julia_repo_gh, pr_params; auth = auth)
        end
        return nothing
    end
    return nothing
end
