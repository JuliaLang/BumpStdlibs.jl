```@meta
CurrentModule = BumpStdlibs
```

# Usage

If you are a member of the `JuliaLang` organization, and you want to run
the BumpStdlibs action now, here are the steps:
1. Go to [this URL](https://github.com/JuliaLang/BumpStdlibs.jl/actions/workflows/BumpStdlibs.yml).
2. In the section that says "This workflow has a `workflow_dispatch` event trigger", click on the `Run workflow` button.
3. Under "Use workflow from", make sure that you have selected the `master` branch
4. Under "Comma-separated list of stdlibs to include":
    - If you want to update all stdlibs, you can leave the default value of `all`
    - If you only want to update a selected set of stdlibs, enter the list, comma-separated. For example:
        - `Pkg`
        - `Downloads,Statistics,Tar`
5. Click on the green `Run workflow` button.
