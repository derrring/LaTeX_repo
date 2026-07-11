#!/usr/bin/env python3
import os
import sys
import subprocess
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
    """Atomically install a link, refusing to replace real files/directories."""
    if not src_path.exists():
        print(
            f"Warning: Source directory '{src_path}' does not exist. Skipping.",
            file=sys.stderr,
        )
        return False

    print(f"Preparing to link '{src_path.name}'...")

    if dest_path.exists() and not dest_path.is_symlink():
        print(
            f"Error: refusing to replace non-symlink destination '{dest_path}'.",
            file=sys.stderr,
        )
        return False

    temp_path = dest_path.with_name(f".{dest_path.name}.tmp-{os.getpid()}")
    try:
        temp_path.unlink(missing_ok=True)
        temp_path.symlink_to(src_path, target_is_directory=True)
        temp_path.replace(dest_path)
        print(
            f"Successfully linked:\n  Source: '{src_path}'\n  Destination: '{dest_path}'\n"
        )
        return True
    except OSError as e:
        temp_path.unlink(missing_ok=True)
        print(f"Error creating symbolic link: {e}", file=sys.stderr)
        print(
            "On Windows, you may need to run this script with administrator privileges.",
            file=sys.stderr,
        )
        return False


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

    unsafe_destinations = [
        dest_base_dir / src_path.name
        for src_path in source_dirs
        if (dest_base_dir / src_path.name).exists()
        and not (dest_base_dir / src_path.name).is_symlink()
    ]
    if unsafe_destinations:
        for destination in unsafe_destinations:
            print(
                f"Error: refusing to replace non-symlink destination '{destination}'.",
                file=sys.stderr,
            )
        sys.exit(1)

    # Create the links
    links_ok = True
    for src_path in source_dirs:
        links_ok = link_directory(src_path, dest_base_dir / src_path.name) and links_ok
        print("-" * 20)

    if not links_ok:
        print("One or more links could not be installed.", file=sys.stderr)
        sys.exit(1)

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
        sys.exit(1)


if __name__ == "__main__":
    main()
