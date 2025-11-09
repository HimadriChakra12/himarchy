#!/bin/bash
set -e

# Detect --noconfirm flag
NOCONFIRM_FLAG=""
if [[ "$1" == "--noconfirm" || "$1" == "-y" ]]; then
    NOCONFIRM_FLAG="--noconfirm"
fi

# Ensure git is available
if ! command -v git &>/dev/null; then
    echo "Error: git is not installed."
    exit 1
fi

# Clone or update repo
if [ ! -d "$HOME/himarchy" ]; then
    echo "Cloning Himarchy..."
    git clone "https://github.com/himadrichakra12/himarchy.git" "$HOME/himarchy"
else
    echo "Updating Himarchy..."
    cd "$HOME/himarchy" || exit 1
    git pull --rebase --autostash
fi

cd "$HOME/himarchy" || exit 1

# Make scripts executable
chmod +x symlink.sh defaults.sh packages.sh remove-application.sh

# Run scripts
./symlink.sh
./defaults.sh
./packages.sh "$NOCONFIRM_FLAG"
./remove-application.sh
