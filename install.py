import argparse
import os
import subprocess
import sys
import zipfile

import requests


def main(args):

    # update the submodules unless the user specifies otherwise
    if args["update_submodules"]:
        update_submodules()

    subprocess.run([sys.executable, "default_assets/manifests.py"])

    # handle the extension setup mode
    if args["extension_setup"] != "SKIP":
        download_success = False

        # try to download and install the extension
        if args["extension_setup"] != "COMPILE_ONLY":
            download_success = download_and_install_extension()

        # if the download wasn't successful and shouldn't be compiled, exit
        if not download_success and args["extension_setup"] == "DOWNLOAD_ONLY":
            print("Failed to download extension")
            sys.exit(1)

        # if the extension can be compiled and the download wasn't successful, try to compile it
        if not download_success:
            print("Compiling extension")
            subprocess.run([sys.executable, "utility_scripts/compile.py"])


def download_and_install_extension() -> bool:
    # get the current tag using git
    tag = subprocess.run(["git", "tag", "--points-at", "HEAD"], capture_output=True)
    tag = tag.stdout.decode().strip()

    if not tag:
        print("Failed to get current tag")
        return False

    # Download latest extension.zip pre-release
    git_url = subprocess.run(["git", "config", "--get", "remote.origin.url"], capture_output=True)
    git_url = git_url.stdout.decode().strip()

    if not git_url:
        print("Failed to get remote origin url")
        return False

    if not git_url.startswith("https://github.com"):
        print("Only GitHub repositories are supported using http are supported")
        return False

    url = git_url.replace("https://github.com", "https://api.github.com/repos")

    releases_url = f"{url}/releases"
    releases = requests.get(releases_url).json()
    release_found = False
    extension_zip = os.path.join('.', 'extension.zip')

    for release in releases:
        if release['tag_name'] != tag:
            continue

        for asset in release['assets']:
            if asset['name'] != 'extension.zip':
                continue

            download_url = asset['browser_download_url']
            response = requests.get(download_url)
            with open(extension_zip, 'wb') as file:
                file.write(response.content)

            print("Downloaded latest pre-release extension.zip")
            release_found = True
            break

        break

    if not release_found:
        print("No pre-release extension.zip found")
        return False

    # Extract extension.zip into the bin directory
    with zipfile.ZipFile(extension_zip, 'r') as zip_ref:
        zip_ref.extractall()
    
    os.remove(extension_zip)

    print("Extracted extension")
    return True


def update_submodules():
    # Run git submodule update --init
    subprocess.run(["git", "submodule", "update", "--init"])


if __name__ == "__main__":
    # change to the project root, which is the dir of this file
    script_dir = os.path.abspath(os.path.dirname(os.path.realpath(__file__)))
    os.chdir(script_dir)

    parser = argparse.ArgumentParser(
        description="setup the openchamp project"
    )

    parser.add_argument(
        "--skip_submodules",
        action="store_false",
        help="Skip updating submodules",
        dest="update_submodules",
        default=True,
    )

    parser.add_argument(
        "--extension_setup",
        type=str,
        required=False,
        choices=["DOWNLOAD_ONLY", "DOWNLOAD_OR_COMPILE", "COMPILE_ONLY", "SKIP"],
        default="DOWNLOAD_OR_COMPILE",
        help="The extension setup mode (default: DOWNLOAD_OR_COMPILE)",
    )

    args = vars(parser.parse_args())

    main(args)
