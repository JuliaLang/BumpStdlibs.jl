function current_branch()
    return chomp(read(`git rev-parse --abbrev-ref HEAD`, String))
end

function get_age_of_commit(commit)
    commit_date_string = strip(read(`git show -s --format=%cI $(commit)`, String))
    commit_date = TimeZones.ZonedDateTime(commit_date_string, "yyyy-mm-ddTHH:MM:SSzzzz")
    now = TimeZones.ZonedDateTime(TimeZones.now(), TimeZones.localzone())
    age = max(now - commit_date, Dates.Millisecond(0))
    return age
end

function get_origin_branches()
    run(`git fetch --all --prune`)
    x1 = read(`git branch -a`, String)
    x2 = strip.(strip.(strip.(split(strip(x1), '\n')), '*'))
    origin_branches = String[]
    for x3 in x2
        x4 = x3 * " "
        m = match(r"^remotes\/origin\/([\w\_\-\\\/]*?) ", x4)
        if !(m isa Nothing)
            x5 = strip(m[1])
            if x5 != "HEAD"
                push!(origin_branches, x5)
            end
        end
    end
    unique!(origin_branches)
    sort!(origin_branches)
    return origin_branches
end

function delete_branch_on_origin(branch_name)
    run(`git push origin --delete $(branch_name)`)
    return nothing
end

function parse_branch_name(original_str::AbstractString)
    str = strip(original_str)
    let
        r = r"^BumpStdlibs\/([A-Za-z0-9]*?)-([a-z0-9]*?)-(.*?)$" # without suffix
        m = match(r, str)
        if m !== nothing
            stdlib = m[1]
            commit = m[2]
            target_branch = m[3]
            return (; stdlib, commit, target_branch)
        end
    end
    let
        r = r"^BumpStdlibs-[\d]*?\/([A-Za-z0-9]*?)-([a-z0-9]*?)-(.*?)$" # with suffix
        m = match(r, str)
        if m !== nothing
            stdlib = m[1]
            commit = m[2]
            target_branch = m[3]
            return (; stdlib, commit, target_branch)
        end
    end
    return nothing
end

function branch_matches_stdlib_and_target_branch(; branch_name, stdlib, target_branch)
    info = parse_branch_name(branch_name)
    if info === nothing
        return false
    end
    return ((stdlib == info.stdlib ) && (target_branch == info.target_branch))
end

function generate_predicate_branch_matches_stdlib_and_target_branch(; stdlib, target_branch)
    predicate = branch_name -> branch_matches_stdlib_and_target_branch(;
        branch_name,
        stdlib,
        target_branch,
    )
    return predicate
end

function find_branches_to_delete(predicate::Function, older_than::Dates.AbstractTime; exclude = String[])
    branches_to_delete = String[]
    for branch_name in get_origin_branches()
        if predicate(branch_name) && !(branch_name in exclude)
            commit = strip(read(`git rev-parse origin/$(branch_name)`, String))
            age = get_age_of_commit(commit)
            if age >= older_than
                push!(branches_to_delete, branch_name)
            end
        end
    end
    return branches_to_delete
end

function delete_branches(branches::Vector{String})
    for branch_name in branches
        @info "Attempting to delete branch" branch_name
        try
            delete_branch_on_origin(branch_name)
            @info "Successfully deleted branch" branch_name
        catch ex
            @info "Encountered an error while trying to delete branch" exception=(ex, catch_backtrace()) branch_name
        end
    end
    return nothing
end

function git_diff_is_empty(x::AbstractString, y::AbstractString)
    return isempty(strip(read(`git diff $(x) $(y)`, String)))
end
