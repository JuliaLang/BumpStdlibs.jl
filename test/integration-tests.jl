@testset "integration tests" begin
    julia_repo = "bcbi-test/julia"
    auth = BumpStdlibs.get_auth_from_environment("BUMPSTDLIBS_TOKEN_FOR_TESTS")
    suffix = Random.randstring(16)
    pr_title_suffix = " $(suffix)"
    pr_branch_suffix = "-$(suffix)"
    for i = 1:2
        result = bump_stdlibs(
            julia_repo;
            auth = auth,
            pr_branch_suffix = pr_branch_suffix,
            pr_title_suffix = pr_title_suffix,
        )
        @test result isa Nothing
    end
end
