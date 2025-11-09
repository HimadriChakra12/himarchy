dotfiles=(
  "$HOME/himarchy/.config:$HOME/.config"
  "$HOME/himarchy/custom:$HOME/.local/share/applications/custom"
  "$HOME/himarchy/bin:$HOME/bin"
  "$HOME/himarchy/bashrc:$HOME/bashrc"
  "$HOME/himarchy/.tmux.conf:$HOME/.tmux.conf"
)

echo "Linking dotfiles..."
for entry in "${dotfiles[@]}"; do
  src="${entry%%:*}"
  tgt="${entry##*:}"
  echo "Linking $src → $tgt"
  rm "$tgt" -r
  ln -sf "$src" "$tgt"
done
copy=(
    "$HOME/himarchy/nemo/scripts:$HOME/.local/share/nemo"
    "$HOME/himarchy/omarchy:$HOME/.local/share"
)
echo "Copying copies..."
for entry in "${copy[@]}"; do
  src="${entry%%:*}"
  tgt="${entry##*:}"
  echo "Linking $src → $tgt"
  cp -rf "$src" "$tgt"
done
