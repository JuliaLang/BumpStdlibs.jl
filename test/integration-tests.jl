@testset "integration tests" begin
    julia_repo = "bcbi-test/julia"

    global_kwargs = Dict(
        :auth => BumpStdlibs.get_input_from_environment(:auth, "BUMPSTDLIBS_TOKEN_FOR_TESTS"),
        :close_old_pull_requests => true,
        :close_old_pull_requests_older_than => Dates.Minute(5),
        :julia_repo_target_branch => "master",
        :pr_branch_suffix => Random.randstring('0':'9', 4),
        :push_if_no_changes => true,
        :stdlibs_to_include => "Pkg",
    )

    @testset "all stdlibs" begin
        @testset "push_if_no_changes = true" begin
            kwargs = deepcopy(global_kwargs)
            kwargs[:push_if_no_changes] = true
            kwargs[:stdlibs_to_include] = "all"
            result = bump_stdlibs(julia_repo; kwargs...)
            @test result isa Nothing
        end
        @testset "push_if_no_changes = false" begin
            kwargs = deepcopy(global_kwargs)
            kwargs[:push_if_no_changes] = false
            kwargs[:stdlibs_to_include] = "all"
            result = bump_stdlibs(julia_repo; kwargs...)
            @test result isa Nothing
        end
    end

    @testset "only specified stdlibs" begin
        kwargs = deepcopy(global_kwargs)
        result = bump_stdlibs(julia_repo; kwargs...)
        @test result isa Nothing
    end
end
