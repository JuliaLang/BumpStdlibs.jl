```@meta
CurrentModule = BumpStdlibs
```

# Usage

If you are a `JuliaLang` committer, and you want to run
the BumpStdlibs action now, here are the steps:
1. Go to [this URL](https://github.com/JuliaLang/BumpStdlibs.jl/actions/workflows/BumpStdlibs.yml).[^1]
2. In the section that says "This workflow has a `workflow_dispatch` event trigger", click on the `Run workflow` button.
3. Under "Use workflow from", make sure that you have selected the `master` branch
4. Under "Target branch", enter `master` if you want to target the Julia master branch, or enter e.g. `backports-release-1.9` if you want to apply these changes to the Julia 1.9 release branch.
5. Under "Comma-separated list of stdlibs to include":
    - If you want to update all stdlibs, you can leave the default value of `all`
    - If you only want to update a selected set of stdlibs, enter the list, comma-separated. For example:
        - `Pkg`
        - `Downloads,Statistics,Tar`
6. Click on the green `Run workflow` button.

[^1]: If that link does not work, go to the [BumpStdlibs.jl repository](https://github.com/JuliaLang/BumpStdlibs.jl), click on the [Actions tab](https://github.com/JuliaLang/BumpStdlibs.jl/actions), and then click on "BumpStdlibs" (in the left-hand sidebar, under "Workflows").
