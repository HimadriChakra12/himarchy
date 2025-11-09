#!/bin/bash
# file_sorter.sh
# Usage: ./file_sorter.sh [directory]
# If no directory is given, it will use the current directory

DIR="${1:-.}"

# Check if directory exists
if [ ! -d "$DIR" ]; then
    echo "Directory $DIR does not exist."
    exit 1
fi

# Loop through all files in the directory
for file in "$DIR"/*; do
    # Skip if not a regular file
    [ -f "$file" ] || continue

    # Extract file extension
    ext="${file##*.}"
    ext_lower=$(echo "$ext" | tr '[:upper:]' '[:lower:]')  # convert to lowercase

    # If the file has no extension, put it in 'others'
    if [ "$ext_lower" = "$file" ]; then
        ext_lower="others"
    fi

    # Create directory for the extension if it doesn't exist
    mkdir -p "$DIR/$ext_lower"

    # Move the file into the corresponding folder
    mv "$file" "$DIR/$ext_lower/"
done

echo "Files sorted in $DIR by extension."

