using CMakeBuilds
using Base.Test


@test isfile(cmake_executable)
run(`$cmake_executable`)
