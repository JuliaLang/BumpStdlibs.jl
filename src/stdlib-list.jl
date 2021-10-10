function get_stdlib_list(upstream::GitHub.Repo, branch_name::AbstractString; auth)
    return mktempdir() do temp_dir
        return cd(temp_dir) do
            list = Vector{StdlibInfo}(undef, 0)
            upstream_clone_url = "https://github.com/$(upstream.full_name).git"
            run(`git clone $(upstream_clone_url) UPSTREAM`)
            return cd("UPSTREAM") do
                run(`git checkout $(branch_name)`)
                my_regex_2 = r"^([\w]*?)_GIT_URL[\s]*?:=[\s]*?([^\n\r]*)$"
                my_regex_3 = r"^([\w]*?)\.version$"
                my_regex_4 = r"^([\w]*?)_BRANCH[\s]*?=[\s]*?([\w\-\.]*?)$"
                my_regex_5 = r"^([\w]*?)_(SHA[\w\d]*?)[\s]*?=[\s]*?([\w]*?)$"
                for filename in readdir("stdlib")
                    if isfile(joinpath("stdlib", filename))
                        m3 = match(my_regex_3, filename)
                        if !(m3 isa Nothing)
                            name = m3[1]
                            current_shas = Dict{String, String}()
                            branch_dict = Dict{Symbol, String}()
                            stdlib_version_lines = split(read(joinpath("stdlib", "$(name).version"), String), '\n')
                            for stdlib_version_line in stdlib_version_lines
                                m2 = match(my_regex_2, stdlib_version_line)
                                m4 = match(my_regex_4, stdlib_version_line)
                                m5 = match(my_regex_5, stdlib_version_line)
                                if !(m2 isa Nothing)
                                    branch_dict[:git_url] = m2[2]
                                elseif !(m4 isa Nothing)
                                    branch_dict[:branch] = m4[2]
                                elseif !(m5 isa Nothing)
                                    current_shas[lowercase(m5[2])] = m5[3]
                                end
                            end
                            @assert haskey(branch_dict, :branch) "$filename is missing a _BRANCH = entry"
                            @assert haskey(branch_dict, :git_url) "$filename is missing a _GIT_URL := entry"
                            branch = branch_dict[:branch]
                            git_url = branch_dict[:git_url]
                            stdlib = StdlibInfo(;
                                name = name,
                                branch = branch,
                                git_url = git_url,
                                current_shas = current_shas
                            )
                            push!(list, stdlib)
                        end
                    end
                end
                return list
            end # cd("UPSTREAM")
        end # cd(temp_dir)
    end # mktempdir()
end
