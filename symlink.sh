dotfiles=(
  "$HOME/himarchy/.config:$HOME/.config"
  "$HOME/himarchy/omarchy/omarchy:$HOME/.local/share/omarchy"
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
  ln -sf "$src" "$tgt"
done


