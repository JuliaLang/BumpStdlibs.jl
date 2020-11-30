"""
```
Base.@kwdef struct StdlibInfo
    name::String
    branch::String
    git_url::String
    current_shas::Dict{String, String}
end
```
"""
Base.@kwdef struct StdlibInfo
    name::String
    branch::String
    git_url::String
    current_shas::Dict{String, String}
end
