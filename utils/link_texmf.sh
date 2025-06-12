#!/bin/bash

# This script creates symbolic links from the project's style directories
# to the user's TEXMFHOME directory, making the custom LaTeX classes and
# Beamer themes available to the TeX system.

# Get the absolute path of the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# --- Configuration ---
# Source directories within your repository
STYLE_SRC_DIR="e_style"
BEAMER_SRC_DIR="MyEspressoTheme"

# --- Script Logic ---
# Find the TEXMFHOME directory
TEXMFHOME=$(kpsewhich -var-value TEXMFHOME)

if [ -z "$TEXMFHOME" ]; then
    echo "Error: TEXMFHOME variable not found."
    echo "Please ensure your TeX distribution is configured correctly."
    exit 1
fi

# The base destination for LaTeX packages
DEST_BASE_DIR="$TEXMFHOME/tex/latex"

# Create the base destination directory if it doesn't exist
mkdir -p "$DEST_BASE_DIR"

echo "TEXMFHOME is: $TEXMFHOME"
echo "Linking styles to: $DEST_BASE_DIR"
echo ""

# --- Link the 'estyle' directory ---
SRC_PATH_STYLE="$REPO_ROOT/$STYLE_SRC_DIR"
DEST_PATH_STYLE="$DEST_BASE_DIR/$STYLE_SRC_DIR"

if [ -e "$SRC_PATH_STYLE" ]; then
    echo "Linking class/style directory..."
    # Remove existing link/directory at the destination to avoid conflicts
    rm -rf "$DEST_PATH_STYLE"
    # Create the symbolic link
    ln -s "$SRC_PATH_STYLE" "$DEST_PATH_STYLE"
    echo "  '$SRC_PATH_STYLE' -> '$DEST_PATH_STYLE'"
else
    echo "Warning: Source directory '$STYLE_SRC_DIR' not found. Skipping."
fi

# --- Link the 'MyEspressoTheme' directory ---
SRC_PATH_BEAMER="$REPO_ROOT/$BEAMER_SRC_DIR"
DEST_PATH_BEAMER="$DEST_BASE_DIR/$BEAMER_SRC_DIR"

if [ -e "$SRC_PATH_BEAMER" ]; then
    echo "Linking Beamer theme directory..."
    # Remove existing link/directory at the destination
    rm -rf "$DEST_PATH_BEAMER"
    # Create the symbolic link
    ln -s "$SRC_PATH_BEAMER" "$DEST_PATH_BEAMER"
    echo "  '$SRC_PATH_BEAMER' -> '$DEST_PATH_BEAMER'"
else
    echo "Warning: Source directory '$BEAMER_SRC_DIR' not found. Skipping."
fi

echo ""
echo "Done linking files."

# --- Update the TeX file database ---
echo "Running texhash to update the database for $TEXMFHOME..."
texhash "$TEXMFHOME" 
echo "Database updated successfully."