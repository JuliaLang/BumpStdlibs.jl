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

function delete_branches_with_prefix_on_origin_older_than(prefix::AbstractString,
                                                          older_than::Dates.AbstractTime;
                                                          exclude = String[])
    for branch_name in get_origin_branches()
        if startswith(branch_name, prefix)
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
