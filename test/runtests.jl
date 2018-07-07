using CMakeWrapper
using BinDeps
using Test


@test isfile(cmake_executable)
run(`$cmake_executable --version`)

ctx = BinDeps.PackageContext(true,
                             pwd(),
                             "CMakeWrapperTest",
                             [])
libdep = BinDeps._library_dependency(ctx, "libfoo")
libdep.helpers = [(BinDeps.NetworkSource(URI("src")), Dict{Symbol, Any}(:filename=>"foo.zip"))]
process = CMakeProcess()
steps = BinDeps.generate_steps(libdep, process, Dict())
