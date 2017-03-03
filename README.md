# CMakeWrapper

[![Build Status](https://travis-ci.org/rdeits/CMakeWrapper.jl.svg?branch=master)](https://travis-ci.org/rdeits/CMakeWrapper.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/iyaryc8ev5yeks0g?svg=true)](https://ci.appveyor.com/project/rdeits/cmakewrapper-jl)
[![codecov.io](http://codecov.io/github/rdeits/CMakeWrapper.jl/coverage.svg?branch=master)](http://codecov.io/github/rdeits/CMakeWrapper.jl?branch=master)

This package is designed to make it easier for Julia packages to build binary dependencies that use CMake. It automatically downloads a modern version of CMake (3.8.0, instead of the Ubuntu 14.04 default of 2.8.12), and it provides a [BinDeps.jl](https://github.com/JuliaLang/BinDeps.jl)-compatible `CMakeProcess` class for automatically building CMake dependencies.

# Installation

    julia> Pkg.clone("https://github.com/rdeits/CMakeWrapper.jl.git")

    julia> Pkg.build("CMakeWrapper")

# Usage

You can declare a `CMakeProcess` similarly to the way you would use the `Autotools` provider in BinDeps.jl. In your `deps/build.jl` file, this would look like:

    provides(Sources,
        URI(source_url),
        dependency_name)

    provides(BuildProcess, CMakeProcess(),
             dependency_name)

where `source_url` and `dependency_name` are set elsewhere in your `build.jl`.

You can also pass raw cmake options directly with the `cmake_args` flag:

    provides(BuildProcess, CMakeProcess(cmake_args=["-DCMAKE_BUILD_TYPE=Debug"]),
             dependency_name)

If the high-level provider doesn't work for you, you can also use the lower-level `CMakeBuild`, analogous to the `AutotoolsDependency` in BinDeps.jl:

    CMakeBuild(srcdir=source_dir,  # where the CMakeLists.txt resides in your source
               builddir=build_dir,  # where the cmake build outputs should go
               prefix=install_prefix,  # desired install prefix
               libtarget=[library_name],  # name of the library being built
               installed_libpath=[path_to_intalled_library],  # expected installed library path
               cmake_args=[],  # additional cmake arguments
               targetname="install")  # build target to run (default: "install")

