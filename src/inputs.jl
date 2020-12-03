const INPUTS = Dict{Symbol, Any}(
    :auth                    => ("BUMPSTDLIBS_TOKEN",                   nothing),
    :close_old_pull_requests => ("BUMPSTDLIBS_CLOSE_OLD_PULL_REQUESTS", "true"),
    :push_if_no_changes      => ("BUMPSTDLIBS_PUSH_IF_NO_CHANGES",      "false"),
    :stdlibs_to_include      => ("BUMPSTDLIBS_STDLIBS_TO_INCLUDE",      "all"),
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
                                    env_var_name::Union{AbstractString, Nothing} = nothing)
    if haskey(INPUTS, input)
        default_env_var_name, default_value = INPUTS[input]
        if env_var_name isa Nothing
            env_var_name_to_use = default_env_var_name
        else
            env_var_name_to_use = env_var_name
        end
        env_var_contents = strip(get(ENV, env_var_name_to_use, ""))
        if isempty(env_var_contents)
            if default_value isa Nothing
                throw(ArgumentError("Either the `$(_env_var_name)` environment variable is undefined, or it is defined but empty."))
            else
                return post_process_input(Val(input), default_value)
            end
        else
            return post_process_input(Val(input), env_var_contents)
        end
    end
    throw(ArgumentError("$(input) is not a valid input"))
end
