#!/bin/bash

remove=(
  "1password:$HOME/.local/share/applications/1password.desktop"
  "Figma:$HOME/.local/share/applications/Figma.desktop"
  "Github:$HOME/.local/share/applications/Github.desktop"
  "Dropbox:$HOME/.local/share/applications/Dropbox.desktop"
)

echo "Removing Extra Applications..."
for entry in "${remove[@]}"; do
  src="${entry%%:*}"
  tgt="${entry##*:}"
  
  if [ -f "$tgt" ]; then
      rm "$tgt"
      echo "Removed $src"
  else
      echo "Skipped $src (not found)"
  fi
done
