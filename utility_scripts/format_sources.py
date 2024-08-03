import argparse
import os
import platform
import subprocess
import stat
import shutil

from pathlib import Path
from typing import List

project_dirs = [
    'scenes',
    'scripts',
    'ui',
]


# Files that should not be formatted
# These are files that are generated by the engine, or cause issues when formatted
ignored_files = [
    # ScalingsBuilder has multiline lambda functions, which are not supported by gdformat and cause a crash
    'scalings_builder.gd',
]

def get_all_gdscript_files(project_dir: str) -> List[Path]:
    all_gdscript_files = []
    for dir in project_dirs:
        for root, dirs, files in os.walk(os.path.join(project_dir, dir)):
            for file in files:
                if file in ignored_files:
                    continue
                
                new_file = Path(os.path.join(root, file))
                if new_file.suffix == '.gd':
                    all_gdscript_files.append(new_file)

    return all_gdscript_files

if __name__ == "__main__":
    script_dir = os.path.abspath(os.path.dirname(os.path.realpath(__file__)))
    project_dir = os.path.abspath(os.path.join(script_dir, '..'))
    
    parser = argparse.ArgumentParser(
        description="apply formatting to all gdscript files"
    )

    parser.add_argument(
        "mode",
        type=str,
        choices=["CHECK", "FORMAT"],
        help="A script to format all the gdscript files in the project, or to check if they are formatted",
    )

    args = vars(parser.parse_args())

    if shutil.which("gdformat") is None:
        print("gdformat not found in PATH. Exiting!")
        exit(1)

    check_only = args["mode"] == "CHECK"
    invalid_files = []

    for file in get_all_gdscript_files(project_dir):
        format_command = ["gdformat"]
        if check_only:
            format_command.append("--check")
        
        format_command.append(str(file))
        print(format_command)

        format_result = subprocess.run(format_command, cwd=project_dir, check=False)

        if format_result.returncode != 0:
            invalid_files.append(file)


    if len(invalid_files) > 0:
        print("The following files are not formatted:")
        for file in invalid_files:
            print(file)
        
        exit(1)
    else:
        print("All files are formatted!")

