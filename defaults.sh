echo "
Defaulting Apps
---------------
"
echo "Creating local .desktop entries if missing..."
mkdir -p ~/.local/share/applications
if [ ! -f ~/.local/share/applications/firefox.desktop ]; then
  echo "Creating firefox.desktop..."
  cat > ~/.local/share/applications/firefox.desktop <<EOF
[Desktop Entry]
Name=Firefox
Exec=firefox %u
Type=Application
Icon=firefox
Terminal=false
Categories=Network;WebBrowser;
MimeType=x-scheme-handler/http;x-scheme-handler/https;
StartupNotify=true
EOF
fi
if [ ! -f ~/.local/share/applications/nemo.desktop ]; then
  echo "Creating nemo.desktop..."
  cat > ~/.local/share/applications/nemo.desktop <<EOF
[Desktop Entry]
Name=Nemo
Exec=nemo %U
Type=Application
Icon=folder
Terminal=false
Categories=System;FileTools;FileManager;
MimeType=inode/directory;
EOF
fi
echo "Setting default applications..."
xdg-settings set default-web-browser firefox.desktop
echo "Firefox set as default browser"
echo "Setting Qimgv as default image viewer..."
for mime in image/jpeg image/png image/gif image/webp image/svg+xml; do
  xdg-mime default qimgv.desktop "$mime"
done
echo "Setting MPV as default video player..."
for mime in video/mp4 video/x-matroska video/x-msvideo video/webm; do
  xdg-mime default mpv.desktop "$mime"
done
echo "Setting Rhythmbox as default music player..."
for mime in audio/mpeg audio/x-wav audio/ogg audio/flac; do
  xdg-mime default rhythmbox.desktop "$mime"
done
xdg-mime default nemo.desktop inode/directory
xdg-settings set default-file-manager nemo.desktop
echo "Nemo set as default file manager"
