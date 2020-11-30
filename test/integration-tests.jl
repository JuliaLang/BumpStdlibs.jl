@testset "integration tests" begin
    julia_repo = "bcbi-test/julia"
    auth = BumpStdlibs.get_auth_from_environment("BUMPSTDLIBS_TOKEN_FOR_TESTS")
    pr_branch_suffix = "-$(Random.randstring(16))"

    @testset "all stdlibs" begin
        stdlibs_to_include = "all"
        result = bump_stdlibs(
            julia_repo;
            auth = auth,
            pr_branch_suffix = pr_branch_suffix,
            stdlibs_to_include = stdlibs_to_include,
        )
        @test result isa Nothing
    end

    @testset "only specified stdlibs" begin
        stdlibs_to_include = "Pkg"
        result = bump_stdlibs(
            julia_repo;
            auth = auth,
            pr_branch_suffix = pr_branch_suffix,
            stdlibs_to_include = stdlibs_to_include,
        )
        @test result isa Nothing
    end

    @testset "Override the default branch" begin
        julia_repo_default_branch = "master"
        stdlibs_to_include = "Pkg"
        result = bump_stdlibs(
            julia_repo;
            auth = auth,
            pr_branch_suffix = pr_branch_suffix,
            stdlibs_to_include = stdlibs_to_include,
        )
        @test result isa Nothing
    end
end
