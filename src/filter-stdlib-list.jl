function filter_stdlib_list(stdlib_list::AbstractVector{StdlibInfo}, stdlibs_to_include::AbstractString)::Vector{StdlibInfo}
    _stdlibs_to_include_string = strip(stdlibs_to_include)
    if ( isempty(_stdlibs_to_include_string) ) || ( lowercase(_stdlibs_to_include_string) == "all" )
        return stdlib_list
    else
        _stdlibs_to_include_vector = convert(Vector{String}, strip.(split(_stdlibs_to_include_string, ",")))::Vector{String}
        return filter_stdlib_list(stdlib_list, _stdlibs_to_include_vector)
    end
end

function filter_stdlib_list(stdlib_list::AbstractVector{<:StdlibInfo}, stdlibs_to_include::AbstractVector{<:AbstractString})::Vector{StdlibInfo}
    filtered_stdlib_list = Vector{StdlibInfo}(undef, 0)
    for stdlib in stdlib_list
        if stdlib.name in stdlibs_to_include
            push!(filtered_stdlib_list, stdlib)
        end
    end
    return filtered_stdlib_list
end
