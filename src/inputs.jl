function get_auth_from_environment(environment_variable_name::AbstractString = "BUMPSTDLIBS_TOKEN")
    if haskey(ENV, environment_variable_name)
        token = strip(ENV[environment_variable_name])
        if isempty(token)
            throw(ArgumentError("The `$(environment_variable_name)` environment variable is defined but empty."))
        else
            @debug("Got token from `$(environment_variable_name)` environment variable. Attempting to authenticate...")
            auth = GitHub.authenticate(token)
            @debug("Successfully authenticated.")
            return auth
        end
    else
        throw(ArgumentError("The `$(environment_variable_name)` environment variable is not defined."))
    end
end

function get_stdlibs_to_include_from_environment(environment_variable_name::AbstractString = "BUMPSTDLIBS_STDLIBS_TO_INCLUDE")::String
    return get(ENV,environment_variable_name, "all")
end
