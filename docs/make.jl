using BumpStdlibs
using Documenter

makedocs(;
    modules=[BumpStdlibs],
    authors="Dilum Aluthge and contributors",
    repo="https://github.com/JuliaLang/BumpStdlibs.jl/blob/{commit}{path}#L{line}",
    sitename="BumpStdlibs.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://JuliaLang.github.io/BumpStdlibs.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Usage" => "usage.md",
        "API" => "api.md",
    ],
    linkcheck=true,
)

deploydocs(;
    repo="github.com/JuliaLang/BumpStdlibs.jl",
)
