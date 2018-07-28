using CMake, Test

@test isfile(cmake)
@test occursin("cmake version", read(`$cmake --version`, String))
