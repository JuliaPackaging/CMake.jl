# CMake

[![Build Status](https://travis-ci.org/JuliaPackaging/CMake.jl.svg?branch=master)](https://travis-ci.org/JuliaPackaging/CMake.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/49wbo3l6pyw8gh69/branch/master?svg=true)](https://ci.appveyor.com/project/StevenGJohnson/cmake-jl/branch/master)
[![codecov.io](http://codecov.io/github/JuliaPackaging/CMake.jl/coverage.svg?branch=master)](http://codecov.io/github/JuliaPackaging/CMake.jl?branch=master)

This package is designed to make it easier for Julia packages to build binary dependencies that use CMake. It automatically downloads a modern version of CMake (3.7.2, instead of the Ubuntu 14.04 default of 2.8.12), and it exports a constant `cmake` giving the path of this executable.

For a [BinDeps.jl](https://github.com/JuliaLang/BinDeps.jl)-compatible `CMakeProcess` class for automatically building CMake dependencies,
see the [CMakeWrapper.jl](https://github.com/JuliaPackaging/CMakeWrapper.jl) package.

# Installation

    julia> Pkg.add("CMake")

# Usage

`using CMake` gives you access to a constant string `cmake` giving
the path of the `cmake` executable.
