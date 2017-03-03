module CMakeWrapper

depsjl = joinpath(dirname(dirname(@__FILE__)), "deps", "deps.jl")
if !isfile(depsjl)
    error("CMakeWrapper not properly installed. Please run\nPkg.build(\"CMakeWrapper\")")
else
    include(depsjl)
end

export cmake_executable

end # module
