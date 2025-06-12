#!/usr/bin/env python3
import os,sys
import subprocess
import platform
import shutil
from pathlib import Path

"""
This script creates symbolic links from the project's style directories
(estyle, MyEspressoTheme) to the user's TEXMFHOME directory, making the 
custom LaTeX classes and Beamer themes available to the TeX system.

Variables:
- TEXMFHOME: The directory where user-specific TeX files are stored.
    - The script uses `kpsewhich` to find the TEXMFHOME directory.
- estyle: The directory containing custom LaTeX styles.
- MyEspressoTheme: The directory containing the custom Beamer theme.
- src_path: The source path of the directories to link.
    - beamer_src_path: The source path of the Beamer theme directory.
    - style_src_path: The source path of the LaTeX styles directory.
- dest_base_dir: The base directory in TEXMFHOME where the links will be created.
- dest_path: The destination path in TEXMFHOME where the links will be created.

"""


def get_texmf_home():
    """Find the TEXMFHOME directory using kpsewhich."""
    try:
        result = subprocess.run(
            ['kpsewhich', '-var-value', 'TEXMFHOME'],
            capture_output=True, text=True, check=True
        )
        path = result.stdout.strip()
        if not path:
            return None
        return Path(path)
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None

def link_directory(src_path: Path, dest_path: Path):
    """Remove the old link/dir and create a new symbolic link."""
    if not src_path.exists():
        raise FileNotFoundError(f"Source directory '{src_path}' does not exist.")
    print(f"Linking '{src_path.name}' directory...")

    # Remove existing link or directory at the destination
    if dest_path.is_symlink() or dest_path.is_file():
        dest_path.unlink()
    elif dest_path.is_dir():
        shutil.rmtree(dest_path)

    # Create the symbolic link
    dest_path.symlink_to(src_path, target_is_directory=True)
    print(f"'{src_path}'\n -> \n'{dest_path}'\n")
    print('=='*10)

def main():
    """Main function to perform the linking and database update."""
    repo_root = Path(__file__).resolve().parent.parent

    # --- Source Directories ---
    style_src_path = repo_root / "e_style"
    beamer_src_path = repo_root / "MyEspressoTheme"

    # --- Find and prepare destination ---
    texmf_home = get_texmf_home()
    if not texmf_home:
        print("Please ensure your TeX distribution is configured correctly.")
        raise FileNotFoundError("Error: TEXMFHOME variable not found.")

    dest_base_dir = texmf_home / "tex" / "latex"
    dest_base_dir.mkdir(parents=True, exist_ok=True)

    print(f"TEXMFHOME is: {texmf_home}")
    print(f"Linking styles to: {dest_base_dir}\n")

    # --- Create the links ---
    link_directory(style_src_path, dest_base_dir / style_src_path.name)
    link_directory(beamer_src_path, dest_base_dir / beamer_src_path.name)

    print("\nDone linking files.")

    # --- Update the TeX file database ---
    print(f"Running texhash to update the file database for {texmf_home}...")
    try:
        # Pass the specific texmf_home path to texhash
        result = subprocess.run(
            ["texhash", str(texmf_home)],  # <-- This line changed
            capture_output=True,
            text=True,
            check=True,
        )
        print("Database updated successfully.")
    except (subprocess.CalledProcessError, FileNotFoundError) as e:
        print("\nError: Failed to run 'texhash'.")
        if isinstance(e, FileNotFoundError):
            print("Please ensure 'texhash' is installed and in your system's PATH.")
        else:
            print("--- texhash error output ---")
            print(e.stderr)
            print("----------------------------")


if __name__ == "__main__":
    main()
