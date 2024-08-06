import argparse
import os
import subprocess
import sys
import platform
import zipfile

if __name__ == "__main__":
    # change to the project root, which is the dir of this file
    script_dir = os.path.abspath(os.path.dirname(os.path.realpath(__file__)))
    os.chdir(os.path.join(script_dir, ".."))

    host_os = platform.system()
    host_arch = platform.machine()

    parser = argparse.ArgumentParser(
        description="setup the openchamp project"
    )

    parser.add_argument(
        "--godot_path",
        type=str,
        default="",
        help="The path to the godot editor console execuatable",
        dest="godot_cmd"
    )

    parser.add_argument(
        "--export_type",
        type=str,
        default="client",
        choices=["client", "server"],
        help="The export type (default: client)",
        dest="export_type"
    )

    parser.add_argument(
        "--export_platform",
        type=str,
        default="native",
        choices=[
            "native",
            "windows_amd64",
            "windows_arm64",
            "linux_amd64",
            "linux_arm64",
            "macos"
        ],
        help="The export platform (default: native)",
        dest="export_platform"
    )

    parser.add_argument(
        "--release_type",
        type=str,
        default="release",
        choices=["release", "debug"],
        help="The release type for the export (default: release)",
        dest="release_type"
    )

    args = vars(parser.parse_args())

    export_platform = args["export_platform"]
    if export_platform == "native":
        match host_os:
            case "Windows":
                if host_arch == "aarch64":
                    export_platform = "windows_arm64"
                else:
                    export_platform = "windows_amd64"
            case "Linux":
                if host_arch == "aarch64":
                    export_platform = "linux_arm64"
                else:
                    export_platform = "linux_amd64"
            case "Darwin":
                export_platform = "macos"

    print(f"Exporting {args['export_type']} for {export_platform} on {host_os} ({host_arch})")

    export_profile = ""
    export_archive = "openchamp"
    if args["export_type"] == "client":
        export_profile = "Client "
        export_archive += "_client"
    else:
        export_profile = "Server "
        export_archive += "_server"

    match export_platform:
        case "windows_amd64":
            export_profile += "Windows (amd64)"
            export_archive += "_windows_amd64.zip"
        case "windows_arm64":
            export_profile += "Windows (arm64)"
            export_archive += "_windows_arm64.zip"
        case "linux_amd64":
            export_profile += "Linux (amd64)"
            export_archive += "_linux_amd64.zip"
        case "linux_arm64":
            export_profile += "Linux (arm64)"
            export_archive += "_linux_arm64.zip"
        case "macos":
            export_profile += "macOS"
            export_archive += "_macos.zip"

    print(f"Exporting \"{export_profile}\" as \"{export_archive}\"")

    # Run the export command
    godot_command = args["godot_cmd"]
    if godot_command == "":
        print("No godot exe given. Exiting!")
        sys.exit(1)

    # check if godot command is executable
    subprocess.run([godot_command, "--version"], check=True)

    # create the export directory
    os.makedirs("build", exist_ok=True)

    # set up the export command
    if args["release_type"] == "debug":
        export_arg = "--export-debug"
    else:
        export_arg = "--export-release"
    
    export_command = [
        godot_command,
        "--headless",
        export_arg,
        export_profile,
        f"build/{export_archive}"
    ]

    # run the export command
    export_output = subprocess.run(export_command, check=True)
