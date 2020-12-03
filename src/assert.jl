function assert_file_contains(filename::AbstractString, pattern)
    filecontents = read(filename, String)
    if !(occursin(pattern, filecontents))
        throw(ErrorException("The file at \"$(filename)\" does not contain the pattern \"$(pattern)\""))
    end
    return nothing
end

function assert_string_startswith(s::AbstractString, prefix::AbstractString)
    if !(startswith(s, prefix))
        throw(ErrorException("\"$(s)\" does not start with \"$(prefix)\""))
    end
    return nothing
end
