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

function delete_branches_with_predicate_on_origin_older_than(predicate::Function,
                                                             older_than::Dates.AbstractTime;
                                                             exclude = String[])
    for branch_name in get_origin_branches()
        if predicate(branch_name)
            commit = strip(read(`git rev-parse origin/$(branch_name)`, String))
            age = get_age_of_commit(commit)
            if !(branch_name in exclude)
                if age >= older_than
                    @info "Attempting to delete branch" branch_name
                    try
                        delete_branch_on_origin(branch_name)
                        @info "Successfully deleted branch" branch_name
                    catch ex
                        @info "Encountered an error while trying to delete branch" exception=(ex, catch_backtrace()) branch_name
                    end

                end
            end
        end
    end
    return nothing
end

function git_diff_is_empty(x::AbstractString, y::AbstractString)
    return isempty(strip(read(`git diff $(x) $(y)`, String)))
end
