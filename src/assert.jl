function current_branch()
    return chomp(read(`git rev-parse --abbrev-ref HEAD`, String))
end

function assert_current_branch_is(branch_name)
    _current_branch = current_branch()
    if _current_branch != branch_name
        throw(ErrorException("Expected current branch to be \"$(branch_name)\", but the current branch is actually \"$(_current_branch)\""))
    end
    return nothing
end

function assert_file_contains(filename::AbstractString, pattern)
    filecontents = read(filename, String)
    if !(occursin(pattern, filecontents))
        throw(ErrorException("The file at \"$(filename)\" does not contain the pattern \"$(pattern)\""))
    end
    return nothing
end
