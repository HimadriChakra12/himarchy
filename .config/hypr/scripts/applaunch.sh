#!/bin/bash
APPLICATION_DIR="$HOME/.local/share/applications"
TMUX_SESSION="apps"

declare -A desktop_map
names=()

# Read all desktop files at once
readarray -d '' files < <(find "$APPLICATION_DIR" -type f -name '*.desktop' -print0 2>/dev/null)

for file in "${files[@]}"; do
    # Extract fields in one grep call
    mapfile -t lines < <(grep -E '^(Name|Exec|NoDisplay|Hidden)=' "$file")

    # Initialize
    name=""
    exec_cmd=""
    nodisplay=""
    hidden=""

    for line in "${lines[@]}"; do
        case "$line" in
            Name=*)      name="${line#Name=}" ;;
            Exec=*)      exec_cmd="${line#Exec=}" ;;
            NoDisplay=*) nodisplay="${line#NoDisplay=}" ;;
            Hidden=*)    hidden="${line#Hidden=}" ;;
        esac
    done

    # Skip unwanted entries
    [[ "$nodisplay" == "true" || "$hidden" == "true" || -z "$name" || -z "$exec_cmd" ]] && continue

    # Remove placeholders (%f, %u, etc.) and trim spaces
    exec_cmd="${exec_cmd//%[a-zA-Z@]/}"
    exec_cmd="${exec_cmd#"${exec_cmd%%[![:space:]]*}"}"
    exec_cmd="${exec_cmd%"${exec_cmd##*[![:space:]]}"}"

    names+=("$name")
    desktop_map["$name"]="$exec_cmd"
done

[ ${#names[@]} -eq 0 ] && exit 0

# FZF selection
# Prepare the FZF interface with styling
selection=$(printf '%s\n' "${names[@]}" | sort -u | fzf \
    --prompt="▶ " \
    --reverse \
    --info=hidden \
    --pointer=" " \
    --marker=" " \
    --cycle)
[ -z "$selection" ] && exit 0

cmd="${desktop_map[$selection]}"

# Start tmux session if needed
tmux has-session -t "$TMUX_SESSION" 2>/dev/null || tmux new-session -d -s "$TMUX_SESSION"
tmux send-keys -t "$TMUX_SESSION" "$cmd" C-m
