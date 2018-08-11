using BinDeps
using BinDeps: MakeTargets

basedir = dirname(@__FILE__)
prefix = joinpath(basedir, "usr")

cmake_version = v"3.7.2"
base_url = "https://cmake.org/files/v$(cmake_version.major).$(cmake_version.minor)"
@static if Sys.iswindows()
    binary_name = "cmake.exe"
else
    binary_name = "cmake"
end

function install_binaries(file_base, file_ext, binary_dir)
    filename = "$(file_base).$(file_ext)"
    url = "$(base_url)/$(filename)"
    binary_path = joinpath(basedir, "downloads", file_base, binary_dir)

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
                symlink(joinpath(binary_path, file),
                        joinpath(prefix, "bin", file))
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

process = @static if Sys.islinux()
    if Sys.ARCH == :x86_64 && !force_source_build
        install_binaries(
            "cmake-$(cmake_version)-Linux-x86_64",
            "tar.gz",
            "bin")
    else
        install_from_source("cmake-$(cmake_version)", "tar.gz")
    end
elseif Sys.isapple()
    if !force_source_build
        install_binaries(
            "cmake-$(cmake_version)-Darwin-x86_64",
            "tar.gz",
            joinpath("CMake.app", "Contents", "bin"))
    else
        install_from_source("cmake-$(cmake_version)", "tar.gz")
    end
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
