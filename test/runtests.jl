using BumpStdlibs
using Test

import Dates
import Random
import TimeZones

@testset "BumpStdlibs.jl" begin
    include("unit-tests.jl")
    include("integration-tests.jl")
end
