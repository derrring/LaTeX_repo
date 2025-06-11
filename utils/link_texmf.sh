#!/bin/bash

# --- USER CONFIGURATION: PLEASE EDIT THIS ---
# The absolute path to your local folder containing .sty, .cls, .bst, etc.
# Examples:
# - Windows: "C:\\Users\\YourUser\\Documents\\MyLatexStyles"
# - macOS/Linux: "/Users/youruser/Documents/MyLatexStyles"
SOURCE_FOLDER="/Users/zvezda/Onedrive/code/LaTeX_repo/" # <--- EDIT THIS!

# --- SCRIPT START ---

# Check if the source folder exists
if [ ! -d "$SOURCE_FOLDER" ]; then
    echo "❌ Error: Source folder '$SOURCE_FOLDER' not found."
    exit 1
fi

# Automatically find the TEXMFHOME path
TEXMF_HOME=$(kpsewhich -var-value=TEXMFHOME)

if [ -z "$TEXMF_HOME" ]; then
    echo "❌ Error: Could not find TEXMFHOME directory. Please ensure TeX is installed correctly."
    exit 1
fi

echo "Found TEXMFHOME directory: $TEXMF_HOME"

# Define the destination for the link
# Custom packages are usually placed in texmf/tex/latex/
DESTINATION_DIR="$TEXMF_HOME/tex/latex/"
LINK_NAME=$(basename "$SOURCE_FOLDER")
FULL_DESTINATION_PATH="$DESTINATION_DIR$LINK_NAME"

# Ensure the parent destination directory exists
mkdir -p "$DESTINATION_DIR"

# Check if the link already exists before trying to create it
if [ -L "$FULL_DESTINATION_PATH" ]; then
    echo "🤔 Link '$FULL_DESTINATION_PATH' already exists. Skipping."
else
    echo "🔗 Creating link: $SOURCE_FOLDER -> $FULL_DESTINATION_PATH"
    # Create the symbolic link
    ln -s "$SOURCE_FOLDER" "$FULL_DESTINATION_PATH"
    echo "✅ Link created successfully!"
fi

# Remind the user to update TeX's file database
echo -e "\n🎉 Process finished. We recommend running 'texhash' or 'mktexlsr' to update TeX's file database."