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
echo "Langs"
yay -S --noconfirm "${langs[@]}"
echo "Shell"
yay -S --noconfirm "${shell[@]}"
echo "Editor"
yay -S --noconfirm "${editor[@]}"
echo "Other"
yay -S --noconfirm "${packages[@]}"
echo "wine"
yay -S --noconfirm "${wine[@]}"
