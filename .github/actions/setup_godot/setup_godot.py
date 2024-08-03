import argparse
import os
import zipfile
import sys
import stat
from pathlib import Path

import wget


def get_dirs(version_string):
    system_type = ""
    export_template_dir = ""
    godot_program_subdir = ""
    godot_console_subdir = ""
    template_version_string = version_string.replace("-", ".")
    match sys.platform:
        case "linux":
            system_type = "linux.x86_64"
            export_template_dir = f"~/.local/share/godot/export_templates/{template_version_string}"
            godot_program_subdir = f"Godot_v{version_string}_linux.x86_64"
            godot_console_subdir = godot_program_subdir
        case "win32" | "cygwin":
            system_type = "win64.exe"
            export_template_dir = f"{os.getenv('APPDATA')}/Godot/export_templates/{template_version_string}"
            godot_program_subdir = f"Godot_v{version_string}_win64.exe"
            godot_console_subdir = f"Godot_v{version_string}_win64_console.exe"
        case "darwin":
            system_type = "macos.universal"
            export_template_dir = f"~/Library/Application Support/Godot/export_templates/{template_version_string}"
            godot_program_subdir = f"Godot.app/Contents/MacOS/Godot"
            godot_console_subdir = godot_program_subdir
        case _:
            print(sys.platform) 
            sys.exit(1)

    export_template_dir = str(Path(export_template_dir).expanduser())

    godot_installs_dir = os.path.join("~", ".godot_installs", version_string)
    godot_installs_dir = str(Path(godot_installs_dir).expanduser())

    return system_type, export_template_dir, godot_installs_dir, godot_program_subdir, godot_console_subdir


def main(args):
    godot_repo = args["godot_repo"]
    godot_version = args["godot_version"]

    system_type, export_template_dir, godot_installs_dir, godot_program_subdir, godot_console_subdir = get_dirs(godot_version)

    # create the .godot_installs dir and the templates dir
    os.makedirs(godot_installs_dir, exist_ok=True)
    os.makedirs(export_template_dir, exist_ok=True)

    # download the godot executable
    godot_exe_zip = f"Godot_v{godot_version}_{system_type}.zip"
    godot_download_link = f"{godot_repo}/releases/download/{godot_version}/{godot_exe_zip}"
    godot_zip = wget.download(godot_download_link)

    # unzip the godot executable
    with zipfile.ZipFile(godot_zip, "r") as zip_ref:
        zip_ref.extractall(godot_installs_dir)

    # remove the zip file
    os.remove(godot_zip)

    # download the export templates
    godot_templates_zip_name = f"Godot_v{godot_version}_export_templates.tpz"
    godot_templates_link = f"{godot_repo}/releases/download/{godot_version}/{godot_templates_zip_name}"
    godot_templates_zip = wget.download(godot_templates_link)

    # unzip the export templates
    with zipfile.ZipFile(godot_templates_zip, "r") as zip_ref:
        zip_ref.extractall(export_template_dir)

    # all the export templates are in the templates subdir. Move them to the root
    templates_subdir = os.path.join(export_template_dir, "templates")
    for file in os.listdir(templates_subdir):
        os.rename(os.path.join(templates_subdir, file), os.path.join(export_template_dir, file))

    # remove the zip file
    os.remove(godot_templates_zip)



if __name__ == "__main__":
    # change to the project root, which is the dir of this file
    script_dir = os.path.abspath(os.path.dirname(os.path.realpath(__file__)))
    os.chdir(script_dir)

    parser = argparse.ArgumentParser(
        description="setup the godot executable"
    )

    parser.add_argument(
        "--godot_repo",
        action="store",
        help="The repository to download the godot executable from",
        default="https://github.com/godotengine/godot-builds",
        dest="godot_repo",
        required=False,
    )

    parser.add_argument(
        "--godot_version",
        action="store",
        help="The version tag to download",
        default="4.3-rc1",
        dest="godot_version",
        required=False,
    )

    parser.add_argument(
        "action",
        action="store",
        choices=["download", "print_console", "print_program"],
        help="The action to perform",
    )

    args = vars(parser.parse_args())

    if args["action"] == "download":
        main(args)
    else:
        _, _, godot_installs_dir, godot_program_subdir, godot_console_subdir = get_dirs(args["godot_version"])
        godot_exe = ""
        var_name = ""

        if args["action"] == "print_console":
            godot_exe = os.path.join(godot_installs_dir, godot_console_subdir)
            var_name = "GODOT_CONSOLE_EXE"
            
        elif args["action"] == "print_program":
            godot_exe = os.path.join(godot_installs_dir, godot_program_subdir)
            var_name = "GODOT_EXE"

        godot_exe = str(Path(godot_exe).as_posix())
        print(godot_exe)
        os.chmod(
            godot_exe,
            os.stat(godot_exe).st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH
        )

        # set and export the environment variables for the godot executable
        env_file = os.getenv('GITHUB_OUTPUT')
        with open(env_file, "a") as file:
            file.write(f"{var_name}={godot_exe}\n")
    
