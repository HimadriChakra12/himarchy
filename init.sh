#!/bin/bash

# Detect --noconfirm flag
NOCONFIRM_FLAG=""
if [[ "$1" == "--noconfirm" || "$1" == "-y" ]]; then
    NOCONFIRM_FLAG="--noconfirm"
fi

if [ ! -d "$HOME/himarchy" ]; then
    git clone "https://github.com/himadrichakra12/himarchy.git" "$HOME/himarchy"
    cd "$HOME/himarchy" || exit 1
else
    cd "$HOME/himarchy" || exit 1
    git pull
fi

chmod +x symlink.sh defaults.sh packages.sh remove-application.sh

./symlink.sh
./defaults.sh
./packages.sh "$NOCONFIRM_FLAG"
./remove-application.sh
