git clone "https://github.com/himadrichakra12/himarchy.git"
scripts=(
    "$HOME/himarchy/symlink.sh"
    "$HOME/himarchy/defaults.sh"
    "$HOME/himarchy/packages.sh"
    "$HOME/himarchy/remove-application.sh"
)

echo "Removing Extra Application..."
chmod +x "${scripts[@]}"
./"${scripts[@]}"
