@testset "unit tests" begin
    @testset "find_branches_to_delete" begin
        predicate = BumpStdlibs.generate_predicate_branch_matches_stdlib_and_target_branch(;
            stdlib = "Pkg", target_branch = "master",
        )
        heads = Dict(
            "BumpStdlibs/Pkg-aaaaaaaaa-master" => "a",
            "BumpStdlibs/Pkg-bbbbbbbbb-master" => "b",
            "BumpStdlibs/Pkg-ccccccccc-release-1.13" => "c",
            "BumpStdlibs/Downloads-ddddddddd-master" => "d",
            "master" => "e",
        )
        ages = Dict("a" => Dates.Hour(2), "b" => Dates.Minute(1), "c" => Dates.Hour(2), "d" => Dates.Hour(2), "e" => Dates.Hour(2))
        age_of = sha -> ages[sha]
        @test BumpStdlibs.find_branches_to_delete(predicate, Dates.Hour(1), heads, age_of) == ["BumpStdlibs/Pkg-aaaaaaaaa-master"]
        @test BumpStdlibs.find_branches_to_delete(predicate, Dates.Minute(0), heads, age_of) ==
            ["BumpStdlibs/Pkg-aaaaaaaaa-master", "BumpStdlibs/Pkg-bbbbbbbbb-master"]
        @test BumpStdlibs.find_branches_to_delete(predicate, Dates.Minute(0), heads, age_of; exclude = ["BumpStdlibs/Pkg-aaaaaaaaa-master"]) ==
            ["BumpStdlibs/Pkg-bbbbbbbbb-master"]
    end
    @testset "ls_remote_heads" begin
        mktempdir() do dir
            run(`git -C $(dir) init --quiet --initial-branch=main`)
            run(`git -C $(dir) -c user.name=t -c user.email=t@t commit --quiet --allow-empty -m init`)
            run(`git -C $(dir) branch other`)
            heads = BumpStdlibs.ls_remote_heads(dir)
            @test sort!(collect(keys(heads))) == ["main", "other"]
            @test heads["main"] == heads["other"]
            @test heads["main"] == strip(read(`git -C $(dir) rev-parse HEAD`, String))
        end
    end
end
