#!/bin/bash

# This script creates symbolic links from the project's style directories
# to the user's TEXMFHOME directory, making the custom LaTeX classes and
# Beamer themes available to the TeX system.

# --- MODIFICATION: Exit immediately if a command exits with a non-zero status. ---
set -e

# Get the absolute path of the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# --- Configuration ---
# An array of source directories within your repository
SOURCE_DIRS=("e_style" "MyEspressoTheme" "MyCV")

# --- Script Logic ---
# Find the TEXMFHOME directory
TEXMFHOME=$(kpsewhich -var-value TEXMFHOME)

if [ -z "$TEXMFHOME" ]; then
    echo "Error: TEXMFHOME variable not found." >&2
    echo "Please ensure your TeX distribution is configured correctly." >&2
    exit 1
fi

# The base destination for LaTeX packages
DEST_BASE_DIR="$TEXMFHOME/tex/latex"

# Create the base destination directory if it doesn't exist
mkdir -p "$DEST_BASE_DIR"

echo "TEXMFHOME is: $TEXMFHOME"
echo "Linking styles to: $DEST_BASE_DIR"
echo "========================================"

# --- MODIFICATION: Loop through the array of directories ---
for dir in "${SOURCE_DIRS[@]}"; do
    SRC_PATH="$REPO_ROOT/$dir"
    DEST_PATH="$DEST_BASE_DIR/$dir"

    if [ -d "$SRC_PATH" ]; then
        echo "Processing '$dir' directory..."

        # Remove existing link/directory at the destination to avoid conflicts
        # Use -f to avoid errors if it doesn't exist
        rm -rf "$DEST_PATH"

        # Create the symbolic link
        ln -s "$SRC_PATH" "$DEST_PATH"
        echo "  Successfully linked '$SRC_PATH' -> '$DEST_PATH'"
    else
        echo "Warning: Source directory '$dir' not found at '$SRC_PATH'. Skipping." >&2
    fi
    echo "----------------------------------------"
done
# --- END MODIFICATION ---


echo "Done linking files."
echo ""

# --- Update the TeX file database ---
echo "Running texhash to update the database for '$TEXMFHOME'..."
texhash "$TEXMFHOME"
echo "Database updated successfully."