@testset "integration tests" begin
    julia_repo = "bcbi-test/julia"

    global_kwargs = Dict(
        :close_old_pull_requests => true,
        :close_old_pull_requests_older_than => Dates.Minute(5),
        :auth => BumpStdlibs.get_input_from_environment(:auth, "BUMPSTDLIBS_TOKEN_FOR_TESTS"),
        :pr_branch_suffix => Random.randstring(4),
    )

    @testset "all stdlibs" begin
        result = bump_stdlibs(
            julia_repo;
            stdlibs_to_include = "all",
            global_kwargs...
        )
        @test result isa Nothing
    end

    @testset "only specified stdlibs" begin
        result = bump_stdlibs(
            julia_repo;
            stdlibs_to_include = "Pkg",
            global_kwargs...
        )
        @test result isa Nothing
    end

    @testset "Override the default branch" begin
        result = bump_stdlibs(
            julia_repo;
            julia_repo_default_branch = "master",
            stdlibs_to_include = "Pkg",
            global_kwargs...
        )
        @test result isa Nothing
    end
end
