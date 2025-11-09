remove=(
  "1password:$HOME/.local/share/application/1password.desktop"
  "Figma:$HOME/.local/share/application/Figma.desktop"
  "Github:$HOME/.local/share/application/Github.desktop"
  "Dropbox:$HOME/.local/share/application/Dropbox.desktop"
)

echo "Removing Extra Application..."
for entry in "${remove[@]}"; do
  tgt="${entry##*:}"
  src="${entry%%:*}"
  rm "$tgt"
  echo "Removed $src"
donev
