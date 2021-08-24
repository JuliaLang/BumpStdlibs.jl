# Some of the code in this file is taken from Registrator.jl (license: MIT)
# https://github.com/JuliaRegistries/Registrator.jl
#
# Some of the code in this file is taken from BinaryBuilder.jl (license: MIT)
# https://github.com/JuliaPackaging/BinaryBuilder.jl

function parse_github_exception(ex::ErrorException)
    msgs = map(strip, split(ex.msg, '\n'))
    d = Dict()
    for m in msgs
        a, b = split(m, ":"; limit=2)
        d[a] = strip(b)
    end
    return d
end

function is_pr_exists_exception(ex)
    d = parse_github_exception(ex)

    if d["Status Code"] == "422" &&
       match(r"A pull request already exists", d["Errors"]) !== nothing
        return true
    end

    return false
end

function _get_token_from_auth(auth::GitHub.OAuth2)
    return auth.token
end

function whoami_username(; auth)
    io = IOBuffer()
    Downloads.download(
        "https://api.github.com/user",
        io;
        headers = Dict(
            "Authorization" => "token $(_get_token_from_auth(auth))",
        ),
    )
    str = String(take!(io))
    json = JSON3.read(str)
    login = json.login::String
    return login
end

function create_or_update_pull_request(repo::GitHub.Repo, params; auth)
    whoami = whoami_username(; auth)
    try
        @info "Attempting to create a new pull request..."
        new_pr = GitHub.create_pull_request(
            repo;
            params=params,
            auth=auth,
        )
        @info "Created new pull request" new_pr
        return new_pr
    catch ex
        @debug("", exception=(ex, catch_backtrace()))
        if is_pr_exists_exception(ex)
            found_prs, _ = GitHub.pull_requests(
                repo;
                auth=auth,
                params=Dict(
                    "state" => "open",
                    "base" => params["base"],
                    "head" => params["head"],
                ),
            )
            @debug "" found_prs
            if length(found_prs) != 1
                @warn "length(found_prs) != 1" length(found_prs) found_prs [x.number for x in found_prs]
            end
            found_pr = found_prs[1]
            @info "There is already an existing pull request: $(found_pr.number)"
            @info "Attempting to update the existing pull request..."
            existing_pr = GitHub.update_pull_request(
                repo,
                found_pr.number;
                auth=auth,
                params=params,
            )
            @info "Updated existing pull request" existing_pr
            return existing_pr
        else
            rethrow(ex)
        end
    end
end

function create_or_get_fork(fork::AbstractString, upstream::GitHub.Repo; auth)
    try
        return GitHub.repo(fork; auth = auth)
    catch ex
        @debug("", exception=(ex, catch_backtrace()))
        return GitHub.create_fork(upstream; auth = auth)
    end
end

function update_fork_branch(fork::GitHub.Repo, upstream::GitHub.Repo, branch_name::AbstractString; auth)
    mktempdir() do temp_dir
        cd(temp_dir) do
            upstream_clone_url = "https://github.com/$(upstream.full_name).git"
            token = auth.token
            fork_clone_url = "https://x-access-token:$(token)@github.com/$(fork.full_name).git"
            run(`git clone $(fork_clone_url) FORK`)
            cd("FORK") do
                run(`git remote add upstream $(upstream_clone_url)`)
                run(`git fetch --all --prune`)
                run(`git checkout -B $(branch_name) upstream/$(branch_name)`)
                run(`git pull upstream $(branch_name)`)
                run(`git reset --hard upstream/$(branch_name)`)
                run(`git push --force origin $(branch_name)`)
            end # cd("FORK")
        end # cd(temp_dir)
    end # mktempdir()
    return nothing
end
