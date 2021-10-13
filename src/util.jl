function _try_extract_clickable_url_from_git_url(git_url::AbstractString)
    git_url_stripped = strip(git_url)
    regex_1 = r"^git:\/\/github.com\/([\w\-]*?)\/([\w\-\.]*?).git$"
    m_1 = match(regex_1, git_url_stripped)
    if m_1 !== nothing
        owner = m_1[1]
        repo = m_1[2]
        return "https://github.com/$(owner)/$(repo)"
    end
    return nothing
end

function _git_url_to_formatted_markdown(git_url::AbstractString)
    git_url_stripped = strip(git_url)
    clickable_url_maybe = _try_extract_clickable_url_from_git_url(git_url_stripped)
    if clickable_url_maybe === nothing
        @warn "Could not convert Git URL into a clickable link" git_url
        return "`$(git_url_stripped)`"
    end
    clickable_link_markdown = "[$(clickable_url_maybe)]($(clickable_url_maybe))"
    return clickable_link_markdown
end
