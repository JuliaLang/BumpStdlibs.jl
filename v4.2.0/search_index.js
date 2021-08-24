var documenterSearchIndex = {"docs":
[{"location":"api/","page":"API","title":"API","text":"CurrentModule = BumpStdlibs","category":"page"},{"location":"api/#API","page":"API","title":"API","text":"","category":"section"},{"location":"api/","page":"API","title":"API","text":"","category":"page"},{"location":"api/","page":"API","title":"API","text":"Modules = [BumpStdlibs]","category":"page"},{"location":"api/#BumpStdlibs.StdlibInfo","page":"API","title":"BumpStdlibs.StdlibInfo","text":"Base.@kwdef struct StdlibInfo\n    name::String\n    branch::String\n    git_url::String\n    current_shas::Dict{String, String}\nend\n\n\n\n\n\n","category":"type"},{"location":"api/#BumpStdlibs.bump_stdlibs-Tuple{AbstractString}","page":"API","title":"BumpStdlibs.bump_stdlibs","text":"bump_stdlibs(julia_repo; kwargs...)\n\n\n\n\n\n","category":"method"},{"location":"usage/","page":"Usage","title":"Usage","text":"CurrentModule = BumpStdlibs","category":"page"},{"location":"usage/#Usage","page":"Usage","title":"Usage","text":"","category":"section"},{"location":"usage/","page":"Usage","title":"Usage","text":"If you are a JuliaLang committer, and you want to run the BumpStdlibs action now, here are the steps:","category":"page"},{"location":"usage/","page":"Usage","title":"Usage","text":"Go to this URL.\nIn the section that says \"This workflow has a workflow_dispatch event trigger\", click on the Run workflow button.\nUnder \"Use workflow from\", make sure that you have selected the master branch\nUnder \"Comma-separated list of stdlibs to include\":\nIf you want to update all stdlibs, you can leave the default value of all\nIf you only want to update a selected set of stdlibs, enter the list, comma-separated. For example:\nPkg\nDownloads,Statistics,Tar\nClick on the green Run workflow button.","category":"page"},{"location":"","page":"Home","title":"Home","text":"CurrentModule = BumpStdlibs","category":"page"},{"location":"#BumpStdlibs","page":"Home","title":"BumpStdlibs","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"If you are a JuliaLang committer, and you want to run the BumpStdlibs action now, see the Usage page.","category":"page"},{"location":"","page":"Home","title":"Home","text":"The source code for this package is available in the GitHub repository.","category":"page"}]
}
