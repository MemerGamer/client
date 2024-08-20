import argparse
import os
import zipfile
import sys
import platform
import stat
import shutil
import subprocess
from pathlib import Path

import wget


def install_sys_deps():
    if platform.system() != "Linux":
        print("Can't install build deps for other OS than linux for now")
        return
    
    if shutil.which("apt"):
        subprocess.run([
            "sudo", "apt-get", "install", "-y",
            "g++", "clang", "libc++-dev", "libc++abi-dev",
            "cmake", "ninja-build", "libx11-dev", "libxcursor-dev",
            "libxi-dev", "libgl1-mesa-dev", "libfontconfig1-dev"
        ])
        return
    
    if shutil.which("dnf"):
        subprocess.run([
            "sudo", "dnf", "install", "-y",
            "gcc-c++", "clang", "libcxx-devel", "cmake",
            "ninja-build", "libX11-devel", "libXcursor-devel",
            "libXi-devel", "mesa-libGL-devel", "fontconfig-devel"
        ])
        return
    
    if shutil.which("pacman"):
        subprocess.run([
            "sudo", "pacman", "-S", "gcc", "clang", "libc++", "cmake",
            "ninja", "libx11", "libxcursor", "mesa-libgl", "fontconfig", "libwebp"
        ])
        return
    
    if shutil.which("zypper"):
        subprocess.run([
            "sudo", "zypper", "install", "gcc-c++", "clang", "libc++-devel",
            "libc++abi-devel", "cmake", "ninja", "libX11-devel", "libXcursor-devel",
            "libXi-devel", "Mesa-libGL-devel", "fontconfig-devel"
        ])
        return
    
    print("didn't find a valid package manager")


def compile(script_dir, skia_tag, should_update, linker):
    aesprite_dir=Path(os.path.join(script_dir, "aseprite"))
    
    if aesprite_dir.is_dir() is True:
        if should_update:
            print("pulling the latest commits from the aseprite repo")
            subprocess.run(["git", "pull"], cwd=aesprite_dir)
    else:
        print("cloning the aseprite repo")
        subprocess.run(["git", "clone", "https://github.com/aseprite/aseprite"], cwd=script_dir)
        
    # setup/update the submodules
    subprocess.run(["git", "submodule", "update", "--init", "--recursive"], cwd=aesprite_dir)
    
    # set the skia path
    skia_dir=Path(os.path.join(script_dir, "skia"))
    
    if not skia_dir.is_dir() or should_update:
        build_os=platform.system()
        match build_os:
            case "Windows":
                build_os="Windows"
            case "Linux":
                build_os="Linux"
            case "Darwin":
                build_os="macOS"
            case _:
                print(f"not a valid build os: {build_os}")
                return 1
                
        build_arch=platform.machine()
        match build_arch:
            case "amd64" | "x86_64" | "AMD64":
                build_arch="x64"
            case "i386" | "x86":
                build_arch="x86"
            case "arm64" | "aarch64":
                build_arch="arm64"
            case _:
                print(f"not a valid build arch: {build_arch}")
                return 2
        
        link_suffix=""
        if build_os == "Linux":
            link_suffix="-libstdc++"
        
        
        skia_dl_link = f"https://github.com/aseprite/skia/releases/download/{skia_tag}/Skia-{build_os}-Release-{build_arch}{link_suffix}.zip"
        print(f"downloading the skia binaries from '{skia_dl_link}'")
        
        skia_dl_zip = wget.download(skia_dl_link)
        
        with zipfile.ZipFile(skia_dl_zip, "r") as zip_ref:
            zip_ref.extractall(skia_dir)
        
        os.remove(skia_dl_zip)

    # try setting the linker
    if linker == "" and shutil.which("mold"):
        linker = "MOLD"
    
    if linker:
        print("Using linker: {}".format(linker))
        os.environ["CMAKE_LINKER_TYPE"] = linker
        
    # try running the setup
    setup_command = [
        "cmake",
        "-G", "Ninja",
        "-DCMAKE_BUILD_TYPE=Release",
        "-DLAF_BACKEND=skia",
        f"-DSKIA_DIR={skia_dir}",
        "-B", "build",
        "."
    ]
    setup_output = subprocess.run(setup_command, cwd=aesprite_dir, check=True)
    if setup_output.returncode != 0:
        print("Failed to run the setup command")
        return 4

    # try compiling the code
    compile_command = [
        "cmake",
        "--build", "build"
    ]
    compile_output = subprocess.run(compile_command, cwd=aesprite_dir, check=True)
    if setup_output.returncode != 0:
        print("Failed to run the compile command")
        return 5


if __name__ == "__main__":
    # change to the project root, which is the dir of this file
    script_dir = os.path.abspath(os.path.dirname(os.path.realpath(__file__)))
    os.chdir(script_dir)

    parser = argparse.ArgumentParser(
        description="compile/run aseprite"
    )

    parser.add_argument(
        "--skia_tag",
        action="store",
        help="The skia version tag to use during compile/update",
        default="m102-861e4743af",
        dest="skia_tag",
        required=False,
    )
    
    parser.add_argument(
        "--set_linker",
        type=str,
        required=False,
        default="",
        help="The linker to use (default: empty, tries to use mold if installed)"
    )

    parser.add_argument(
        "--cleanup",
        action='store_true',
        required=False,
        default=False,
        dest='cleanup',
        help="delete the aseprite and skia dirs"
    )

    parser.add_argument(
        "--system_deps",
        action='store_true',
        required=False,
        default=False,
        dest='cleanup',
        help="install system build deps"
    )
    
    parser.add_argument(
        "action",
        action="store",
        choices=["compile", "update", "run"],
        help="The action to perform",
    )

    args = vars(parser.parse_args())

    match args["action"]:
        case "run":
            aesprite_exe = os.path.join(script_dir, "aseprite", "build", "bin", "aseprite")
            subprocess.run(aesprite_exe)
        case "update" | "compile" as operation:
            if args["cleanup"]:
                shutil.rmtree("aseprite")
                shutil.rmtree("skia")
                
            if args["system_deps"]:
                install_sys_deps()
                
            sys.exit(compile(script_dir, args["skia_tag"], operation == "update", args["set_linker"]))
    
