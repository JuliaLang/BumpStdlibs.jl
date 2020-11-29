using BumpStdlibs
using Test

import Random

@testset "BumpStdlibs.jl" begin
    include("unit-tests.jl")
    include("integration-tests.jl")
end
