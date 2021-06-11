function delete_checksum_lines(; checksum_file::AbstractString,
                                 stdlib_name::AbstractString)
    lines = readlines(checksum_file)
    f = line -> startswith(strip(line), "$(stdlib_name)-")
    file_contains_matching_lines = any(f, lines)
    filter!(!f, lines)
    rm(checksum_file; force = true, recursive = true)
    open(checksum_file, "w") do io
        for line in lines
            line_stripped = strip(line)
            if !isempty(line_stripped)
                println(io, line_stripped)
            end
        end
    end
    return file_contains_matching_lines
end
