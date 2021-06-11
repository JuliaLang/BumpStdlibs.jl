function get_stdlib_list(upstream::GitHub.Repo, branch_name::AbstractString; auth)
    return mktempdir() do temp_dir
        return cd(temp_dir) do
            list = Vector{StdlibInfo}(undef, 0)
            upstream_clone_url = "https://github.com/$(upstream.full_name).git"
            run(`git clone $(upstream_clone_url) UPSTREAM`)
            return cd("UPSTREAM") do
                run(`git checkout $(branch_name)`)
                my_regex_1 = r"^([\w]*?)[\s]*?\:= ([\w:\/\.]*?)$"
                my_regex_2 = r"^([\w]*?)_GIT_URL$"
                my_regex_3 = r"^([\w]*?)\.version$"
                my_regex_4 = r"^([\w]*?)_BRANCH[\s]*?=[\s]*?([\w\-\.]*?)$"
                my_regex_5 = r"^([\w]*?)_(SHA[\w\d]*?)[\s]*?=[\s]*?([\w]*?)$"
                makefile_lines = split(read(joinpath("stdlib", "Makefile"), String), '\n')
                stdlib_to_git_url = Dict{String, String}()
                for makefile_line in makefile_lines
                    m1 = match(my_regex_1, makefile_line)
                    if !(m1 isa Nothing)
                        LHS = m1[1]
                        RHS = m1[2]
                        m2 = match(my_regex_2, LHS)
                        if !(m2 isa Nothing)
                            stdlib_to_git_url[m2[1]] = RHS
                        end
                    end
                end
                for filename in readdir("stdlib")
                    if isfile(joinpath("stdlib", filename))
                        m3 = match(my_regex_3, filename)
                        if !(m3 isa Nothing)
                            name = m3[1]
                            name_alluppercase = uppercase(name)
                            git_url = stdlib_to_git_url[name_alluppercase]
                            current_shas = Dict{String, String}()
                            branch_dict = Dict{Symbol, String}()
                            stdlib_version_lines = split(read(joinpath("stdlib", "$(name).version"), String), '\n')
                            for stdlib_version_line in stdlib_version_lines
                                m4 = match(my_regex_4, stdlib_version_line)
                                m5 = match(my_regex_5, stdlib_version_line)
                                if !(m4 isa Nothing)
                                    branch_dict[:branch] = m4[2]
                                elseif !(m5 isa Nothing)
                                    current_shas[lowercase(m5[2])] = m5[3]
                                end
                            end
                            branch = branch_dict[:branch]
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
