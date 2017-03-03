# CMakeWrapper

[![Build Status](https://travis-ci.org/rdeits/CMakeWrapper.jl.svg?branch=master)](https://travis-ci.org/rdeits/CMakeWrapper.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/iyaryc8ev5yeks0g?svg=true)](https://ci.appveyor.com/project/rdeits/cmakewrapper-jl)
[![codecov.io](http://codecov.io/github/rdeits/CMakeWrapper.jl/coverage.svg?branch=master)](http://codecov.io/github/rdeits/CMakeWrapper.jl?branch=master)

This package is designed to make it easier for Julia packages to build binary dependencies that use CMake. It automatically downloads a modern version of CMake (3.8.0, instead of the Ubuntu 14.04 default of 2.8.12), and it provides a [BinDeps.jl](https://github.com/JuliaLang/BinDeps.jl)-compatible `CMakeProcess` class for automatically building CMake dependencies. 

