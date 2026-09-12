# Some of the code in this file is taken from Registrator.jl (license: MIT)
# https://github.com/JuliaRegistries/Registrator.jl
#
# Some of the code in this file is taken from BinaryBuilder.jl (license: MIT)
# https://github.com/JuliaPackaging/BinaryBuilder.jl

function parse_github_exception(ex::ErrorException)
    msgs = map(strip, split(ex.msg, '\n'))
    d = Dict()
    for m in msgs
        parts = split(m, ":"; limit=2)
        if length(parts) == 2
            d[parts[1]] = strip(parts[2])
        end
    end
    return d
end

function is_pr_exists_exception(ex)
    d = parse_github_exception(ex)

    if get(d, "Status Code", "") == "422" &&
       match(r"A pull request already exists", get(d, "Errors", "")) !== nothing
        return true
    end

    return false
end

function _get_token_from_auth(auth::GitHub.OAuth2)
    return auth.token
end

# One call against the REST API. Returns the parsed JSON body (`nothing` for an empty one)
# and throws on a non-2xx status.
function github_api(method::AbstractString, path::AbstractString; auth, body = nothing)
    headers = Dict(
        "Authorization" => "token $(_get_token_from_auth(auth))",
        "Accept" => "application/vnd.github+json",
    )
    response = HTTP.request(
        method,
        "https://api.github.com$(path)",
        headers,
        body === nothing ? UInt8[] : JSON3.write(body);
        status_exception = false,
    )
    if !(200 <= response.status < 300)
        throw(ErrorException("$(method) $(path) failed with status $(response.status): $(String(response.body))"))
    end
    return isempty(response.body) ? nothing : JSON3.read(response.body)
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

# Point the fork's branch at upstream's. GitHub can do that itself: a fork shares its
# objects with the repository it was forked from, so this needs no clone of julia. The
# clone is kept as the fallback for what the API refuses (a branch the fork does not have
# yet, or one that has diverged from upstream).
function update_fork_branch(fork::GitHub.Repo, upstream::GitHub.Repo, branch_name::AbstractString; auth)
    try
        result = github_api("POST", "/repos/$(fork.full_name)/merge-upstream"; auth, body = (; branch = branch_name))
        @info "Synced the fork's branch with upstream" branch_name result.message
        return nothing
    catch ex
        @info "Could not sync the fork's branch through the API, falling back to git" branch_name exception = ex
    end
    mktempdir() do temp_dir
        cd(temp_dir) do
            upstream_clone_url = "https://github.com/$(upstream.full_name).git"
            token = auth.token
            fork_clone_url = "https://x-access-token:$(token)@github.com/$(fork.full_name).git"
            run(`git clone --quiet --filter=blob:none $(fork_clone_url) FORK`)
            cd("FORK") do
                run(`git remote add upstream $(upstream_clone_url)`)
                run(`git fetch --quiet upstream $(branch_name)`)
                run(`git push --force origin upstream/$(branch_name):refs/heads/$(branch_name)`)
            end # cd("FORK")
        end # cd(temp_dir)
    end # mktempdir()
    return nothing
end

# When the commit was made, in UTC.
function commit_date(repo::GitHub.Repo, sha::AbstractString; auth)
    commit = github_api("GET", "/repos/$(repo.full_name)/commits/$(sha)"; auth)
    return Dates.DateTime(chopsuffix(String(commit.commit.committer.date), "Z"))
end

function delete_fork_branches(fork::GitHub.Repo, branches::Vector{String}; auth)
    for branch_name in branches
        @info "Attempting to delete branch" branch_name
        try
            github_api("DELETE", "/repos/$(fork.full_name)/git/refs/heads/$(branch_name)"; auth)
            @info "Successfully deleted branch" branch_name
        catch ex
            @info "Encountered an error while trying to delete branch" exception=(ex, catch_backtrace()) branch_name
        end
    end
    return nothing
end

function find_prs_for_branches(upstream_repo::GitHub.Repo, fork_owner::String, branches::Vector{String}; auth)
    pr_numbers = Int[]
    for branch in branches
        head = "$(fork_owner):$(branch)"
        try
            found_prs, _ = GitHub.pull_requests(
                upstream_repo;
                auth=auth,
                params=Dict(
                    "state" => "open",
                    "head" => head,
                ),
            )
            for pr in found_prs
                push!(pr_numbers, pr.number)
            end
        catch ex
            @debug "Error finding PRs for branch" branch exception=(ex, catch_backtrace())
        end
    end
    return pr_numbers
end
