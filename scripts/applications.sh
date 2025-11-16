#!/bin/bash
# Directory to store custom local desktop files
CUSTOM_DIR="$HOME/.local/share/applications/custom"
mkdir -p "$CUSTOM_DIR"

# List of files to copy
files=(
    "rawtherapee.desktop"
    "obsidian.desktop"
    "localsend.desktop"
)

# Copy each file safely
for f in "${files[@]}"; do
    src="/usr/share/applications/$f"
    if [ -f "$src" ]; then
        cp "$src" "$CUSTOM_DIR/"
    else
        echo "Warning: $src not found"
    fi
done
