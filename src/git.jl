function current_branch()
    return chomp(read(`git rev-parse --abbrev-ref HEAD`, String))
end

# The branches of a repository and their tips, from `git ls-remote`: works on a URL or a
# remote name, and does not need the objects fetched.
function ls_remote_heads(remote::AbstractString)
    heads = Dict{String, String}()
    for line in eachline(`git ls-remote --heads $(remote)`)
        m = match(r"^([0-9a-f]+)\s+refs/heads/(.+)$", strip(line))
        m === nothing && continue
        heads[String(m[2])] = String(m[1])
    end
    return heads
end

get_origin_branches() = sort!(collect(keys(ls_remote_heads("origin"))))

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

# `heads` maps branch names to their tips, `age_of` gives the age of a commit by sha.
function find_branches_to_delete(predicate::Function, older_than::Dates.AbstractTime,
                                 heads::AbstractDict{String, String}, age_of::Function;
                                 exclude = String[])
    branches_to_delete = String[]
    for branch_name in sort!(collect(keys(heads)))
        if predicate(branch_name) && !(branch_name in exclude)
            age = max(age_of(heads[branch_name]), Dates.Millisecond(0))
            if age >= older_than
                push!(branches_to_delete, branch_name)
            end
        end
    end
    return branches_to_delete
end

function git_diff_is_empty(x::AbstractString, y::AbstractString)
    return isempty(strip(read(`git diff $(x) $(y)`, String)))
end
