import os
import subprocess
import platform

# --- USER CONFIGURATION: PLEASE EDIT THIS ---
# The absolute path to your local folder containing .sty, .cls, .bst, etc.
# Examples:
# - Windows: "C:\\Users\\YourUser\\Documents\\MyLatexStyles"
# - macOS/Linux: "/Users/youruser/Documents/MyLatexStyles"
# SOURCE_FOLDER = "/path/to/your/local/latex/folder"  # <--- EDIT THIS!
SOURCE_FOLDER = "/Users/zvezda/Onedrive/code/LaTeX_repo/"  # <--- EDIT THIS!
def get_texmf_home():
    """Gets the user-level texmf root directory."""
    try:
        # 'kpsewhich' is a standard TeX utility to find TeX-related paths
        result = subprocess.run(
            ['kpsewhich', '-var-value=TEXMFHOME'],
            capture_output=True,
            text=True,
            check=True
        )
        return result.stdout.strip()
    except (FileNotFoundError, subprocess.CalledProcessError) as e:
        print(f"❌ Error: Could not find the 'kpsewhich' command.")
        print("Please ensure your TeX/LaTeX distribution is installed correctly and in your system's PATH.")
        print(f"Details: {e}")
        return None

def create_symlink(source, destination_parent, link_name):
    """Creates a symbolic link in the target destination."""
    # Ensure the parent destination directory exists
    os.makedirs(destination_parent, exist_ok=True)
    
    destination_path = os.path.join(destination_parent, link_name)
    
    # Check if a file or link already exists at the destination
    if os.path.lexists(destination_path):
        print(f"🤔 Link '{destination_path}' already exists. Skipping.")
        return

    print(f"🔗 Preparing to link: '{source}' -> '{destination_path}'")
    
    try:
        if platform.system() == "Windows":
            # Creating symlinks on Windows requires admin rights
            # Note the argument order: mklink /D Link Target
            subprocess.run(['mklink', '/D', destination_path, source], shell=True, check=True)
            print("✅ Link created successfully! (Windows)")
        else:
            # For macOS and Linux
            # Note the argument order: ln -s target link_name
            os.symlink(source, destination_path)
            print("✅ Link created successfully! (macOS/Linux)")
    except OSError as e:
        print(f"❌ Error: Link creation failed.")
        if platform.system() == "Windows":
            print("Hint: On Windows, you often need to run this script as an Administrator to create symbolic links.")
        print(f"Details: {e}")
    except Exception as e:
        print(f"❌ An unknown error occurred: {e}")


if __name__ == "__main__":
    texmf_home = get_texmf_home()
    
    if texmf_home and os.path.isdir(SOURCE_FOLDER):
        print(f"Found TEXMFHOME directory: {texmf_home}")
        # Get the folder name from the source path to use as the link name
        link_name = os.path.basename(os.path.normpath(SOURCE_FOLDER))
        
        # The target directory is typically texmf/tex/latex
        destination_dir = os.path.join(texmf_home, "tex", "latex")
        
        create_symlink(SOURCE_FOLDER, destination_dir, link_name)
        
        print("\n🎉 Process finished. You may need to run 'texhash' or 'mktexlsr' to update TeX's file database.")
    elif not texmf_home:
        print("Could not proceed because the TEXMFHOME directory was not found.")
    else:
        print(f"❌ Error: The source folder '{SOURCE_FOLDER}' does not exist or is not a directory. Please check the path.")