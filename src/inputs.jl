const INPUTS = Dict{Symbol, Any}(
    :auth                    => ("BUMPSTDLIBS_TOKEN",                   nothing),
    :close_old_pull_requests => ("BUMPSTDLIBS_CLOSE_OLD_PULL_REQUESTS", "true"),
    :stdlibs_to_include      => ("BUMPSTDLIBS_STDLIBS_TO_INCLUDE",      "all"),
)

function post_process_input(::Val{:auth}, value)
    return GitHub.authenticate(value)
end

function post_process_input(::Val{:close_old_pull_requests}, value)
    return parse(Bool, value)
end

function post_process_input(::Val, value)
    return value
end

function get_input_from_environment(input::Symbol,
                                    env_var_name::Union{AbstractString, Nothing} = nothing)
    if haskey(INPUTS, input)
        default_env_var_name, default_value = INPUTS[input]
        if env_var_name isa Nothing
            _env_var_name = default_env_var_name
        else
            _env_var_name = env_var_name
        end
        if haskey(ENV, _env_var_name)
            environment_variable_contents = strip(ENV[_env_var_name])
            if isempty(environment_variable_contents)
                throw(ArgumentError("The `$(_env_var_name)` environment variable is defined but empty."))
            else
                return post_process_input(Val(input), environment_variable_contents)
            end
        else
            if default_value isa Nothing
                throw(ArgumentError("The `$(_env_var_name)` environment variable is not defined."))
            else
                return post_process_input(Val(input), default_value)
            end
        end
    end
    throw(ArgumentError("$(input) is not a valid input"))
end
