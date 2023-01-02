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

Base.@kwdef struct Config
    auth::GitHub.Authorization = get_input_from_environment(:auth)
    close_old_pull_requests::Bool = get_input_from_environment(:close_old_pull_requests)
    close_old_pull_requests_older_than::Dates.AbstractTime = Dates.Minute(0)
    julia_repo_target_branch::String = get_input_from_environment(:target_branch)
    pr_branch_suffix::String = ""
    push_if_no_changes::Bool = get_input_from_environment(:push_if_no_changes)
    stdlibs_to_include::Union{String, Vector{String}} = get_input_from_environment(:stdlibs_to_include)
end

Base.@kwdef struct State
    all_pr_branches::Vector{String} = String[]
    fork_julia_repo_gh::GitHub.Repo
    upstream_julia_repo_gh::GitHub.Repo
end
