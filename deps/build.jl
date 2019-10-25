using BinDeps
using BinDeps: MakeTargets

basedir = dirname(@__FILE__)
prefix = joinpath(basedir, "usr")

cmake_version = v"3.15.3"
base_url = "https://github.com/Kitware/CMake/releases/download/v$(cmake_version)"
@static if Sys.iswindows()
    binary_name = "cmake.exe"
else
    binary_name = "cmake"
end

function probe_symlink_creation(dest::AbstractString)
    while !isdir(dest)
        dest = dirname(dest)
    end

    # Build arbitrary (non-existent) file path name
    link_path = joinpath(dest, "binaryprovider_symlink_test")
    while ispath(link_path)
        link_path *= "1"
    end

    try
        symlink("foo", link_path)
        return true
    catch e
        if isa(e, Base.IOError)
            return false
        end
        rethrow(e)
    finally
        rm(link_path; force=true)
    end
end

function install_binaries(file_base, file_ext, binary_dir)
    filename = "$(file_base).$(file_ext)"
    url = "$(base_url)/$(filename)"
    binary_path = joinpath(basedir, "downloads", file_base, binary_dir)
    copyderef = get(ENV, "BINARYPROVIDER_COPYDEREF", "") == "true" || !probe_symlink_creation(binary_path)

    @static if Sys.iswindows()
        install_step = () -> begin
            for dir in readdir(dirname(binary_path))
                cp(joinpath(dirname(binary_path), dir),
                   joinpath(prefix, dir);
                   force=true)
            end
        end
    else
        install_step = () -> begin
            for file in readdir(binary_path)
                if !copyderef
                    symlink(joinpath(binary_path, file),
                        joinpath(prefix, "bin", file))
                else
                    cp(joinpath(binary_path, file),
                        joinpath(prefix, "bin", file);
                        force=true)
                end
            end
        end
    end

    function test_step()
        try
            run(`$(joinpath(prefix, "bin", binary_name)) --version`)
        catch e
            error("""
Running the precompiled cmake binary failed with the error
$(e)
To build from source instead, run:
    julia> ENV["CMAKE_JL_BUILD_FROM_SOURCE"] = 1
    julia> Pkg.build("CMake")
""")
        end
    end
    (@build_steps begin
        FileRule(joinpath(prefix, "bin", binary_name),
            (@build_steps begin
                FileDownloader(url, joinpath(basedir, "downloads", filename))
                FileUnpacker(joinpath(basedir, "downloads", filename),
                             joinpath(basedir, "downloads"),
                             "")
                CreateDirectory(joinpath(prefix, "bin"))
                install_step
                test_step
            end))
    end)
end

function install_from_source(file_base, file_ext)
    filename = "$(file_base).$(file_ext)"
    url = "$(base_url)/$(filename)"

    (@build_steps begin
        FileRule(joinpath(prefix, "bin", binary_name),
            (@build_steps begin
                FileDownloader(url, joinpath(basedir, "downloads", filename))
                CreateDirectory(joinpath(basedir, "src"))
                FileUnpacker(joinpath(basedir, "downloads", filename),
                             joinpath(basedir, "src"),
                             "")
                begin
                    ChangeDirectory(joinpath(basedir, "src", file_base))
                    `./configure --prefix=$(prefix)`
                    MakeTargets()
                    MakeTargets("install")
                end
            end))
    end)
end

force_source_build = lowercase(get(ENV, "CMAKE_JL_BUILD_FROM_SOURCE", "")) in ["1", "true"]

process = @static if Sys.isunix()
    result = nothing
    if !force_source_build
        if Sys.islinux() && Sys.ARCH == :x86_64
            result = install_binaries(
                "cmake-$(cmake_version)-Linux-x86_64",
                "tar.gz", "bin")
        elseif Sys.isapple()
            result = install_binaries(
                "cmake-$(cmake_version)-Darwin-x86_64",
                "tar.gz",
                joinpath("CMake.app", "Contents", "bin"))
        end
    end
    if result === nothing
        result = install_from_source("cmake-$(cmake_version)", "tar.gz")
    end
    result
elseif Sys.iswindows()
    if sizeof(Int) == 8
        install_binaries(
            "cmake-$(cmake_version)-win64-x64",
            "zip",
            "bin")
    elseif sizeof(Int) == 4
        install_binaries(
            "cmake-$(cmake_version)-win32-x86",
            "zip",
            "bin")
    else
        error("Only 32- or 64-bit architectures are supported")
    end
else
    error("Sorry, I couldn't recognize your operating system.")
end

run(process)

open(joinpath(dirname(@__FILE__), "deps.jl"), "w") do f
    write(f, """
const cmake = "$(escape_string(joinpath(prefix, "bin", binary_name)))"
""")

end
