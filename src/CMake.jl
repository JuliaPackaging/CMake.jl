VERSION < v"0.7.0-beta2.199" && __precompile__()

"""
The CMake module provides cross-platform installation of a
recent version of `cmake`, and exports a constant `cmake`
giving the path of this `cmake`` executable.
"""
module CMake
export cmake

depsjl = joinpath(dirname(dirname(@__FILE__)), "deps", "deps.jl")
if !isfile(depsjl)
    error("CMake not properly installed. Please run\nPkg.build(\"CMake\")")
else
    include(depsjl)
end

@doc "`cmake` is a `String` giving the path of the `cmake` executable." cmake

end # module
