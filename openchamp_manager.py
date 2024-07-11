import argparse
import requests
import subprocess
import sys


def get_branches(url):
    # Get a list of all branches in a repository
    response = requests.get(url + "/branches").json()
    return [branch['name'] for branch in response]


def clone_branch(url, branch, output_dir):
    # Clone the selected branch
    subprocess.run(["git", "clone", "-b", branch, url, output_dir])


def main(args):
    repo_org = args["org"]
    repo_name = args["repo"]

    repo_api_url = f"https://api.github.com/repos/{repo_org}/{repo_name}"
    repo_clone_url = f"https://github.com/{repo_org}/{repo_name}"

    # Get all branches
    branches = get_branches(repo_api_url)
    if not branches:
        print("No branches found. Are the organization and repository correct?")
        sys.exit(1)

    # If no branch is specified, list all branches and exit
    if not args["branch"]:
        print("No branch specified")
        print("Available branches:")
        for _branch in branches:
            print(_branch)

    # If a branch is specified, check if it exists
    selected_branch = args["branch"]
    if selected_branch not in branches:
        print(f"Branch {selected_branch} not found")
        sys.exit(1)

    # Set the repo directory
    repo_dir = f"openchamp_{repo_org}_{repo_name}_{selected_branch}"

    # Clone the selected branch
    clone_branch(repo_clone_url, selected_branch, repo_dir)

    print(f"Cloned branch {selected_branch} to {repo_dir}")

    # run the install script
    subprocess.run([sys.executable, "install.py"], cwd=repo_dir)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="manage openchamp repo variants"
    )

    parser.add_argument(
        "--org",
        type=str,
        default="openchamp",
        required=False,
        help="The GitHub organization (default: openchamp)"
    )

    parser.add_argument(
        "--repo",
        type=str,
        default="client",
        required=False,
        help="The GitHub repository (default: client)"
    )

    parser.add_argument(
        "--branch",
        type=str,
        required=False,
        default="4.3_update",
        help="The branch to pull"
    )

    args = vars(parser.parse_args())

    main(args)
