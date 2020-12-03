module BumpStdlibs

import GitHub
import HTTP
import URIs

export StdlibInfo
export bump_stdlibs

include("types.jl")

include("assert.jl")
include("bump-stdlibs.jl")
include("filter-stdlib-list.jl")
include("git.jl")
include("github.jl")
include("inputs.jl")
include("stdlib-list.jl")
include("utils.jl")

end # end module BumpStdlibs
