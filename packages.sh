echo "Installing Packages"
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
NOCONFIRM_FLAG="$1"

echo "Installing Languages..."
yay -S ${NOCONFIRM_FLAG} "${langs[@]}"

echo "Installing Shell..."
yay -S ${NOCONFIRM_FLAG} "${shell[@]}"

echo "Installing Editors..."
yay -S ${NOCONFIRM_FLAG} "${editor[@]}"

echo "Installing Other Packages..."
yay -S ${NOCONFIRM_FLAG} "${packages[@]}"

echo "Installing Wine..."
yay -S ${NOCONFIRM_FLAG} "${wine[@]}"
