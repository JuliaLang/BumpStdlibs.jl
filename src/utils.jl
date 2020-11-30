function with_temp_dir(f)
    original_directory = pwd()
    temp_dir = mktempdir(; cleanup = true)
    cd(temp_dir)
    result = f(temp_dir)
    cd(original_directory)
    rm(temp_dir; force = true, recursive = true)
    return result
end
