using Revise
using BumpStdlibs
import GitHub, HTTP, URIs
const StdlibInfo = BumpStdlibs.StdlibInfo
const with_temp_dir = BumpStdlibs.with_temp_dir
const create_or_get_fork = BumpStdlibs.create_or_get_fork
const update_fork_branch = BumpStdlibs.update_fork_branch
const get_auth_from_environment = BumpStdlibs.get_auth_from_environment
const get_stdlibs_to_include_from_environment = BumpStdlibs.get_stdlibs_to_include_from_environment
const get_stdlib_list = BumpStdlibs.get_stdlib_list
const filter_stdlib_list = BumpStdlibs.filter_stdlib_list
const assert_current_branch_is = BumpStdlibs.assert_current_branch_is
const current_branch = BumpStdlibs.current_branch

julia_repo = "bcbi-test/julia"
julia_repo_default_branch = nothing
auth = get_auth_from_environment()
stdlibs_to_include = get_stdlibs_to_include_from_environment()
pr_title_suffix = ""
pr_branch_suffix = ""

# include the contents of bump_stdlibs()

stdlib = filtered_stdlib_list[5]
