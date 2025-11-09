#!/bin/bash
set -e

# Packages
# Packages
packages=(
    "nemo"
    "firefox"
    "qimgv"
    "mpv"
    "qemu"
    "spotify"
    "jdownloader2"
    "qbittorrent"
)
editor=(
    "gimp-devel"
    "rawtherapee"
    "darktable"
)
shell=(
    "curl"
    "github-cli"
    "lazygit"
    "neovim"
    "tmux"
    "cat"
    "7zip"
    "cmus"
    "flatpak"
)
langs=(
    "cmake"
    "make"
    "gcc"
    "golang"
)
wine=(
    "wine-mono"
    "wine-gecko"
    "winetricks"
    "wine"
)
removals=(
    "xournalpp"
    "imv"
    "typora"
)

# Capture --noconfirm flag from argument
NOCONFIRM_FLAG="$1"

# Function to install a category
install_category() {
    local category_name="$1"
    shift
    local packages_list=("$@")
    
    echo "Installing $category_name..."
    if [ ${#packages_list[@]} -eq 0 ]; then
        echo "No packages to install for $category_name."
        return
    fi

    yay -S ${NOCONFIRM_FLAG} "${packages_list[@]}"
}

# Install categories
install_category "Languages" "${langs[@]}"
install_category "Shell tools" "${shell[@]}"
# install_category "Editors" "${editor[@]}"
install_category "Other Packages" "${packages[@]}"
install_category "Wine" "${wine[@]}"

# Optional: remove unwanted packages
if [ ${#removals[@]} -gt 0 ]; then
    echo "Removing unwanted packages..."
    yay -Rns ${NOCONFIRM_FLAG} "${removals[@]}" || true
fi
