const INPUTS = Dict{Symbol, Any}(
    :auth                    => "BUMPSTDLIBS_TOKEN",
    :close_old_pull_requests => "BUMPSTDLIBS_CLOSE_OLD_PULL_REQUESTS",
    :push_if_no_changes      => "BUMPSTDLIBS_PUSH_IF_NO_CHANGES",
    :stdlibs_to_include      => "BUMPSTDLIBS_STDLIBS_TO_INCLUDE",
    :target_branch           => "BUMPSTDLIBS_TARGET_BRANCH",
)

function post_process_input(::Val, value)
    return value
end

function post_process_input(::Val{:auth}, value)
    return GitHub.authenticate(value)
end

function post_process_input(::Val{:close_old_pull_requests}, value)
    return parse(Bool, value)
end

function post_process_input(::Val{:push_if_no_changes}, value)
    return parse(Bool, value)
end

function get_input_from_environment(input::Symbol,
                                    name::Union{AbstractString, Nothing} = nothing)
    if haskey(INPUTS, input)
        default_name = INPUTS[input]
        name = something(name, default_name)
        contents = strip(ENV[name])
        if isempty(contents)
            throw(ArgumentError("The `$name` environment variable is defined but empty."))
        else
            return post_process_input(Val(input), contents)
        end
    end
    throw(ArgumentError("$(input) is not a valid input"))
end
