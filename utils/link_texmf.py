#!/usr/bin/env python3
import os
import sys
import subprocess
import platform
import shutil
from pathlib import Path

"""
This script creates symbolic links from the project's style directories
(estyle, MyEspressoTheme) to the user's TEXMFHOME directory, making the
custom LaTeX classes and Beamer themes available to the TeX system.
"""


def get_texmf_home():
    """Find the TEXMFHOME directory using kpsewhich."""
    try:
        result = subprocess.run(
            ["kpsewhich", "-var-value", "TEXMFHOME"],
            capture_output=True,
            text=True,
            check=True,
        )
        path = result.stdout.strip()
        if not path:
            print(
                "Error: 'kpsewhich -var-value TEXMFHOME' returned an empty path.",
                file=sys.stderr,
            )
            return None
        return Path(path)
    except FileNotFoundError:
        print("Error: 'kpsewhich' command not found.", file=sys.stderr)
        print(
            "Please ensure a TeX distribution (like TeX Live, MiKTeX) is installed and in your PATH.",
            file=sys.stderr,
        )
        return None
    except subprocess.CalledProcessError as e:
        print(f"Error getting TEXMFHOME: {e.stderr}", file=sys.stderr)
        return None


def link_directory(src_path: Path, dest_path: Path):
    """Remove the old link/dir and create a new symbolic link after user confirmation."""
    if not src_path.exists():
        print(
            f"Warning: Source directory '{src_path}' does not exist. Skipping.",
            file=sys.stderr,
        )
        return

    print(f"Preparing to link '{src_path.name}'...")

    # --- MODIFICATION: Added safety check and user confirmation ---
    if dest_path.exists():
        print(
            f"Warning: A file or directory already exists at the destination '{dest_path}'."
        )
        response = (
            input("Do you want to remove it and continue? (y/n): ").lower().strip()
        )
        if response != "y":
            print("Operation cancelled by user. Skipping this directory.")
            return

        # Remove existing link or directory at the destination
        try:
            if dest_path.is_symlink() or dest_path.is_file():
                dest_path.unlink()
            elif dest_path.is_dir():
                shutil.rmtree(dest_path)
            print("Removed existing target.")
        except OSError as e:
            print(f"Error removing '{dest_path}': {e}", file=sys.stderr)
            return
    # --- END MODIFICATION ---

    # Create the symbolic link
    try:
        dest_path.symlink_to(src_path, target_is_directory=True)
        print(
            f"Successfully linked:\n  Source: '{src_path}'\n  Destination: '{dest_path}'\n"
        )
    except OSError as e:
        print(f"Error creating symbolic link: {e}", file=sys.stderr)
        print(
            "On Windows, you may need to run this script with administrator privileges.",
            file=sys.stderr,
        )


def main():
    """Main function to perform the linking and database update."""
    repo_root = Path(__file__).resolve().parent.parent

    # Source Directories
    source_dirs = [repo_root / "e_style", repo_root / "MyEspressoTheme", repo_root / "MyCV"]

    # Find and prepare destination
    texmf_home = get_texmf_home()
    if not texmf_home:
        sys.exit(1)  # Exit if TEXMFHOME can't be found

    dest_base_dir = texmf_home / "tex" / "latex"
    dest_base_dir.mkdir(parents=True, exist_ok=True)

    print(f"TEXMFHOME is: {texmf_home}")
    print(f"Linking styles to: {dest_base_dir}\n{'=='*20}")

    # Create the links
    for src_path in source_dirs:
        link_directory(src_path, dest_base_dir / src_path.name)
        print("-" * 20)

    print("\nDone linking files.")

    # Update the TeX file database
    print(f"Running texhash to update the file database for {texmf_home}...")
    try:
        result = subprocess.run(
            ["texhash", str(texmf_home)], capture_output=True, text=True, check=True
        )
        print("Database updated successfully.")
        if result.stdout:
            print(result.stdout)
    except (subprocess.CalledProcessError, FileNotFoundError) as e:
        print("\nError: Failed to run 'texhash'.", file=sys.stderr)
        if isinstance(e, FileNotFoundError):
            print(
                "Please ensure 'texhash' is installed and in your system's PATH.",
                file=sys.stderr,
            )
        else:
            print(
                f"--- texhash error output ---\n{e.stderr}\n----------------------------",
                file=sys.stderr,
            )


if __name__ == "__main__":
    main()
