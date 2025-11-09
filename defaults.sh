#!/bin/bash
set -e

echo "
Defaulting Apps
---------------
"

# Ensure local applications folder exists
mkdir -p "$HOME/.local/share/applications"

# Helper function to create a .desktop file if missing
create_desktop_entry() {
    local file="$1"
    local content="$2"

    if [ ! -f "$file" ]; then
        echo "Creating $(basename "$file")..."
        cat > "$file" <<EOF
$content
EOF
    fi
}

# Firefox
create_desktop_entry "$HOME/.local/share/applications/firefox.desktop" "[Desktop Entry]
Name=Firefox
Exec=firefox %u
Type=Application
Icon=firefox
Terminal=false
Categories=Network;WebBrowser;
MimeType=x-scheme-handler/http;x-scheme-handler/https;
StartupNotify=true"

# Nemo
create_desktop_entry "$HOME/.local/share/applications/nemo.desktop" "[Desktop Entry]
Name=Nemo
Exec=nemo %U
Type=Application
Icon=folder
Terminal=false
Categories=System;FileTools;FileManager;
MimeType=inode/directory;"

echo "Setting default applications..."

# Default browser (silence warnings)
xdg-settings set default-web-browser firefox.desktop 2>/dev/null
echo "Firefox set as default browser"

# Default image viewer
echo "Setting Qimgv as default image viewer..."
for mime in image/jpeg image/png image/gif image/webp image/svg+xml; do
    xdg-mime default qimgv.desktop "$mime" 2>/dev/null
done

# Default video player
echo "Setting MPV as default video player..."
for mime in video/mp4 video/x-matroska video/x-msvideo video/webm; do
    xdg-mime default mpv.desktop "$mime" 2>/dev/null
done

# Default music player
echo "Setting Rhythmbox as default music player..."
for mime in audio/mpeg audio/x-wav audio/ogg audio/flac; do
    xdg-mime default rhythmbox.desktop "$mime" 2>/dev/null
done

# Default file manager
xdg-mime default nemo.desktop inode/directory 2>/dev/null
xdg-settings set default-file-manager nemo.desktop 2>/dev/null
echo "Nemo set as default file manager"

echo "Default apps setup complete!"
