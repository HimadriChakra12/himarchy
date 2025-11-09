#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

# Name of the tmux session
SESSION_NAME="cmus"

# Check if the tmux session exists
if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    # Start cmus in a new detached tmux session
    tmux new-session -d -s "$SESSION_NAME" "cmus"
    echo "cmus session started in background."
fi
alias cm="tmux attach -t cmus"
alias t="tmux"
alias ta="tmux attach"
alias paci="sudo pacman -S"
alias pacs="sudo pacman -q"
alias yi="yay -S"
alias pi="pikaur -S"
alias ys="yay -q"
alias pks="pikaur -q"
alias ep="nvim ~/.bashrc"
alias v="nvim"
alias q="exit"
alias c="clear"
alias gg="lazygit"
alias update="yay"
alias sour="source ~/.bashrc"
alias fst="fastfetch"
alias cmd="chmod +x"
alias czf="fzf --layout=reverse --header "selector" --height 50%"
gcl(){
    repo=$(gh repo list --limit 100 --json name --jq '.[].name' | fzf)
    cd ~/.git
    git clone https://github.com/HimadriChakra12/$repo
    cd $repo

}
gogit(){
    dir=$(ls ~/.git| fzf)
    cd ~/.git/$dir
    file=$(fzf)
    nvim $file
}
iinstalltar() {
    local tarfile="$1"
    local tempdir
    tempdir="$(mktemp -d /tmp/aurbuild.XXXXXX)"

    if [[ -z "$tarfile" ]]; then
        echo "Usage: installtar <file.tar.gz|tar.xz|tar.zst|tar.bz2>"
        return 1
    fi

    if [[ ! -f "$tarfile" ]]; then
        echo "File not found: $tarfile"
        return 1
    fi

    echo "Copying $tarfile to $tempdir"
    cp "$tarfile" "$tempdir"
    cd "$tempdir" || return 1

    # Extract based on file type
    case "$tarfile" in
        *.tar.gz)  tar -xzf "$(basename "$tarfile")" ;;
        *.tar.xz)  tar -xJf "$(basename "$tarfile")" ;;
        *.tar.zst) tar --use-compress-program=unzstd -xf "$(basename "$tarfile")" ;;
        *.tar.bz2) tar -xjf "$(basename "$tarfile")" ;;
        *) echo "Unsupported file type."; rm -rf "$tempdir"; return 1 ;;
    esac

    # Enter extracted directory
    cd */ || { echo "Could not enter extracted folder."; rm -rf "$tempdir"; return 1; }

    if [[ -f PKGBUILD ]]; then
        echo "Building and installing..."
        makepkg -si --noconfirm
        local result=$?
        echo "Cleaning up..."
        rm -rf "$tempdir"
        return $result
    else
        echo "No PKGBUILD found. Cannot build."
        rm -rf "$tempdir"
        return 1
    fi
}
installtar() {
    local tarfile="$1"
    local tempdir
    tempdir="$(mktemp -d /tmp/aurbuild.XXXXXX)"

    if [[ -z "$tarfile" ]]; then
        echo "Usage: installtar <file.tar.gz|tar.xz|tar.zst|tar.bz2>"
        return 1
    fi

    if [[ ! -f "$tarfile" ]]; then
        echo "File not found: $tarfile"
        return 1
    fi

    echo "Copying $tarfile to $tempdir"
    cp "$tarfile" "$tempdir"
    cd "$tempdir" || return 1

    # Extract based on file type
    case "$tarfile" in
        *.tar.gz)  tar -xzf "$(basename "$tarfile")" ;;
        *.tar.xz)  tar -xJf "$(basename "$tarfile")" ;;
        *.tar.zst) tar --use-compress-program=unzstd -xf "$(basename "$tarfile")" ;;
        *.tar.bz2) tar -xjf "$(basename "$tarfile")" ;;
        *) echo "Unsupported file type."; rm -rf "$tempdir"; return 1 ;;
    esac

    # Enter extracted directory
    cd */ || { echo "Could not enter extracted folder."; rm -rf "$tempdir"; return 1; }

    if [[ -f PKGBUILD ]]; then
        echo "Building and installing..."
        makepkg -si --noconfirm
        local result=$?
        echo "Cleaning up..."
        rm -rf "$tempdir"
        return $result
    else
        echo "No PKGBUILD found. Cannot build."
        rm -rf "$tempdir"
        return 1
    fi
}
flac(){
    read -p "Name of the song: " filename
    read -p "Enter the URL: " url
    yt-dlp -f bestaudio --extract-audio --audio-format flac --audio-quality 0 -o "~/Music/${filename}.flac" "$url"
}

#git aliases
alias gs="git status --short"
#!/bin/bash

zo(){
    # List items, include parent directory ".."
    local items
    items=("..")
    while IFS= read -r line; do
        items+=("$line")
    done < <(ls -1)

    # Use fzf to select an item
    local selected_item
    selected_item=$(printf '%s\n' "${items[@]}" | fzf --layout=reverse --header "$(pwd)" --height 90% --preview "eza --color=always {} -T")

    # If an item was selected
    if [[ -n "$selected_item" ]]; then
        if [[ -d "$selected_item" ]]; then
            cd "$selected_item" || return
            zo  # recursively call zo
        else
            # Open file with default application
            xdg-open "$selected_item" &>/dev/null &
        fi
    fi
}

# Optionally, you can run it directly by calling:
# zo
# Add this to ~/.bashrc
mg() {
    if [ -z "$1" ]; then
        echo "Usage: makeglobal <script_path> [new_name]"
        return 1
    fi

    SCRIPT="$1"
    if [ ! -f "$SCRIPT" ]; then
        echo "Error: File '$SCRIPT' does not exist."
        return 1
    fi

    NAME="${2:-$(basename "$SCRIPT")}"
    DEST="$HOME/bin/$NAME"

    mkdir -p "$HOME/bin"
    if cp "$SCRIPT" "$DEST"; then
        chmod +x "$DEST"
        echo "✅ Script is now global as: $NAME"
    else
        echo "❌ Failed to copy '$SCRIPT' to '$DEST'"
        return 1
    fi
}
reg(){
    url="$1"
    if [ -z "$url" ]; then
        echo "Usage: $0 <url>"
        exit 1
    fi

    # Escape regex special characters
    escaped=$(printf '%s' "$url" | sed -e 's/[.[\*^$()+?{|]/\\&/g' -e 's/\\/\\\\/g')

    # Output anchored regex
    echo "^${escaped}\$"
}
ez() {
    # Find common archive formats and list them in fzf
    archive=$(find . -maxdepth 1 -type f \
        \( -iname "*.zip" -o -iname "*.7z" -o -iname "*.rar" -o -iname "*.tar" -o -iname "*.tar.gz" -o -iname "*.tgz" \) \
        | fzf)

    # Exit if no file selected
    [ -z "$archive" ] && return

    # Make output directory named after archive (without extension)
    dir="${archive%.*}"
    mkdir -p "$dir"

    # Extract using 7z
    7z x "$archive" -o"$dir"
}
