function _try_extract_clickable_url_from_git_url(git_url::AbstractString)
    git_url_stripped = convert(String, strip(git_url))::String
    if startswith(lowercase(git_url_stripped), "https://")
        return git_url_stripped
    end
    return nothing
end

function _git_url_to_formatted_markdown(git_url::AbstractString)
    git_url_stripped = convert(String, strip(git_url))::String
    clickable_url_maybe = _try_extract_clickable_url_from_git_url(git_url_stripped)
    if clickable_url_maybe === nothing
        @warn "Could not convert Git URL into a clickable link" git_url
        return "`$(git_url_stripped)`"
    end
    return clickable_url_maybe
end
