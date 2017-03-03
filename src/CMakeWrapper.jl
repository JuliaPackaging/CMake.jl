__precompile__()

module CMakeWrapper

using Parameters: @with_kw
using BinDeps
using BinDeps: BuildProcess,
               BuildStep,
               @dependent_steps,
               LibraryDependency,
               gethelper,
               builddir,
               stringarray,
               adjust_env
import BinDeps: lower,
                provider,
                generate_steps
export cmake_executable, CMakeBuild, CMakeProcess

depsjl = joinpath(dirname(dirname(@__FILE__)), "deps", "deps.jl")
if !isfile(depsjl)
    error("CMakeWrapper not properly installed. Please run\nPkg.build(\"CMakeWrapper\")")
else
    include(depsjl)
end

const dlext = Libdl.dlext

@with_kw type CMakeBuild <: BuildStep
    srcdir::AbstractString = ""
    builddir::AbstractString = ""
    prefix::AbstractString = ""
    libtarget::Vector{AbstractString} = String[]
    installed_libpath::Vector{AbstractString} = String[]
    cmake_args::Vector{AbstractString} = String[]
    targetname::AbstractString = "install"
    env::Dict{Any, Any} = Dict{Any, Any}()
end

function lower(s::CMakeBuild, collection)
    env = adjust_env(s.env)
    cmake_command = `$cmake_executable -DCMAKE_INSTALL_PREFIX=$(s.prefix)`
    for arg in s.cmake_args
        cmake_command = `$cmake_command $arg`
    end
    build_command = `$cmake_executable --build .`
    if !isempty(s.targetname)
        build_command = `$build_command --target $(s.targetname)`
    end
    @dependent_steps begin
        CreateDirectory(s.builddir)
        begin
            ChangeDirectory(s.builddir)
            FileRule(joinpath(s.builddir, "CMakeCache.txt"),
                     setenv(`$cmake_command $(s.srcdir)`, env))
            FileRule(s.installed_libpath,
                     setenv(build_command, env))
        end
    end
end

type CMakeProcess <: BuildProcess
    source
    opts
end

CMakeProcess(; opts...) = CMakeProcess(nothing, Dict{Any, Any}(opts))

provider(::Type{CMakeProcess}, cm::CMakeProcess; opts...) = cm

function generate_steps(dep::LibraryDependency, h::CMakeProcess, provider_opts)
    if h.source === nothing
        h.source = gethelper(dep,Sources)
    end
    if isa(h.source,Sources)
        h.source = (h.source,Dict{Symbol,Any}())
    end
    h.source[1] === nothing && error("Could not obtain sources for dependency $(dep.name)")
    steps = lower(generate_steps(dep,h.source...))
    opts = Dict()
    opts[:srcdir]   = srcdir(dep,h.source...)
    opts[:prefix]   = usrdir(dep)
    opts[:builddir] = joinpath(builddir(dep),dep.name)
    merge!(opts,h.opts)
    if haskey(opts,:installed_libname)
        !haskey(opts,:installed_libpath) || error("Can't specify both installed_libpath and installed_libname")
        opts[:installed_libpath] = String[joinpath(libdir(dep),opts[:installed_libname])]
        delete!(opts, :installed_libname)
    elseif !haskey(opts,:installed_libpath)
        opts[:installed_libpath] = String[joinpath(libdir(dep),x)*"."*dlext for x in stringarray(get(dep.properties,:aliases,String[]))]
    end
    if !haskey(opts,:libtarget) && haskey(dep.properties,:aliases)
        opts[:libtarget] = String[x*"."*dlext for x in stringarray(dep.properties[:aliases])]
    end
    env = Dict{String,String}()
    if is_unix()
        env["PATH"] = bindir(dep)*":"*ENV["PATH"]
    elseif is_windows()
        env["PATH"] = bindir(dep)*";"*ENV["PATH"]
    end
    haskey(opts,:env) && merge!(env,opts[:env])
    opts[:env] = env
    steps |= CMakeBuild(; opts...)
    steps
end


end # module
