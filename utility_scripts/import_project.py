import argparse
import os
import platform
import subprocess
import stat
import shutil

from pathlib import Path
from typing import List

if __name__ == "__main__":
    script_dir = os.path.abspath(os.path.dirname(os.path.realpath(__file__)))
    project_dir = os.path.join(script_dir, '..')
    
    parser = argparse.ArgumentParser(
        description="import all the assets"
    )

    parser.add_argument(
        "--launcher_command",
        type=str,
        default="",
        help="A command or script used to launch the godot exe",
        dest="launcher_cmd"
    )
    
    parser.add_argument(
        "--godot_path",
        type=str,
        default="",
        help="The path to the godot editor console execuatable",
        dest="godot_cmd"
    )

    args = vars(parser.parse_args())
    print(args)
    
    editor_command = []
    if args["launcher_cmd"] != "":
        launcher_path = Path(args["launcher_cmd"])
        editor_command.append(str(launcher_path))
        
    if args["godot_cmd"] == "":
        print("No godot exe given. Exiting!")
        exit(1)
    
    godot_command = Path(args["godot_cmd"])
    editor_command.append(str(godot_command))
    editor_command.append('--headless')
    editor_command.append('--import')
    
    print(editor_command)
    
    try:
        subprocess.run(editor_command, cwd=project_dir, check=False, timeout=15)
    except:
        print('timeout on try 1')
        
    try:
        subprocess.run(editor_command, cwd=project_dir, check=False, timeout=30)
    except:
        print('timeout on try 2')
    
    import_output = subprocess.run(editor_command, cwd=project_dir, check=True)
    if import_output.returncode != 0:
        print("Failed to import the project")
        exit(1)
