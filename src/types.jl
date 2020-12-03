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

Base.@kwdef struct Config{C1 <: GitHub.Authorization, C2 <: Bool, C3 <: Dates.AbstractTime, C4 <: AbstractString, C5 <: Union{AbstractString, Nothing}, C6 <: Union{AbstractString, AbstractVector{<:AbstractString}}}
    auth::C1 = get_input_from_environment(:auth)
    close_old_pull_requests::C2 = get_input_from_environment(:close_old_pull_requests)
    close_old_pull_requests_older_than::C3 = Dates.Minute(0)
    pr_branch_suffix::C4 = ""
    julia_repo_default_branch::C5 = nothing
    stdlibs_to_include::C6 = get_input_from_environment(:stdlibs_to_include)
end

Base.@kwdef struct State{S1 <: AbstractVector{<:AbstractString}, S2 <: GitHub.Repo, S3 <:AbstractString, S4 <: GitHub.Repo}
    all_pr_branches::S1 = String[]
    fork_julia_repo_gh::S2
    upstream_julia_repo_default_branch::S3
    upstream_julia_repo_gh::S4
end
