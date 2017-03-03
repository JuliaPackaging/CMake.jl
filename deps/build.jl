using BinDeps

basedir = dirname(@__FILE__)
prefix = joinpath(basedir, "usr")

cmake_version = v"3.8.0-rc1"
base_url = "https://cmake.org/files/v$(cmake_version.major).$(cmake_version.minor)"

@static if is_linux()
    download_name = "cmake-$(cmake_version)-Linux-x86_64"
    filename = "$(download_name).tar.gz"
    binary = "cmake"
    binary_path = joinpath("bin", binary)
elseif is_apple()
    download_name = "cmake-$(cmake_version)-Darwin-x86_64"
    filename = "$(download_name).tar.gz"
    binary = "cmake"
    binary_path = joinpath("CMake.app", "Contents", "bin", binary)
elseif is_windows()
    download_name = "cmake-$(cmake_version)-win32-x86"
    filename = "$(download_name).zip"
    binary = "cmake.exe"
    binary_path = joinpath("bin", binary)
else
    error("Sorry, I couldn't recognize your operating system.")
end

url = "$(base_url)/$(filename)"

process = (@build_steps begin
    FileRule(joinpath(prefix, "bin", "cmake"), 
        (@build_steps begin
            FileDownloader(url, joinpath(basedir, "downloads", filename))
            FileUnpacker(joinpath(basedir, "downloads", filename),
                         joinpath(basedir, "downloads"), 
                         "")
            CreateDirectory(joinpath(prefix, "bin"))
            () -> symlink(
                joinpath(basedir, "downloads", 
                         download_name, binary_path), 
                joinpath(prefix, "bin", binary))
        end))
end) 

run(process)

open(joinpath(dirname(@__FILE__), "deps.jl"), "w") do f
    write(f, """
const cmake_executable = "$(joinpath(prefix, "bin", binary))"
""")

end
