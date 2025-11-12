#!/bin/bash
APPLICATION_DIR="$HOME/.local/share/applications"
CACHE_DIR="$HOME/.cache"
CACHE_FILE="$CACHE_DIR/app_launcher_cache"
TMUX_SESSION="apps"

mkdir -p "$CACHE_DIR"

declare -A desktop_map
names=()

update_cache() {
    echo "Updating launcher cache..."
    readarray -d '' files < <(find "$APPLICATION_DIR" -type f -name '*.desktop' -print0 2>/dev/null)

    for file in "${files[@]}"; do
        mapfile -t lines < <(grep -E '^(Name|Exec|NoDisplay|Hidden)=' "$file")
        name=""; exec_cmd=""; nodisplay=""; hidden=""

        for line in "${lines[@]}"; do
            case "$line" in
                Name=*)      name="${line#Name=}" ;;
                Exec=*)      exec_cmd="${line#Exec=}" ;;
                NoDisplay=*) nodisplay="${line#NoDisplay=}" ;;
                Hidden=*)    hidden="${line#Hidden=}" ;;
            esac
        done

        [[ "$nodisplay" == "true" || "$hidden" == "true" || -z "$name" || -z "$exec_cmd" ]] && continue

        exec_cmd="${exec_cmd//%[a-zA-Z@]/}"
        exec_cmd="${exec_cmd#"${exec_cmd%%[![:space:]]*}"}"
        exec_cmd="${exec_cmd%"${exec_cmd##*[![:space:]]}"}"

        names+=("$name")
        desktop_map["$name"]="$exec_cmd"
    done

    # Save to cache
    : > "$CACHE_FILE"
    for name in "${names[@]}"; do
        printf '%s|%s\n' "$name" "${desktop_map[$name]}" >> "$CACHE_FILE"
    done
}

load_cache() {
    while IFS='|' read -r name cmd; do
        [[ -z "$name" || -z "$cmd" ]] && continue
        names+=("$name")
        desktop_map["$name"]="$cmd"
    done < "$CACHE_FILE"
}

# Create cache if missing
if [[ ! -f "$CACHE_FILE" ]]; then
    update_cache
else
    load_cache
    # Check for new or modified .desktop files and update only missing entries
    while IFS= read -r -d '' file; do
        [[ "$file" -nt "$CACHE_FILE" ]] && update_cache && break
        name=$(grep '^Name=' "$file" | head -n1 | cut -d'=' -f2-)
        if [[ -n "$name" && -z "${desktop_map[$name]}" ]]; then
            update_cache
            break
        fi
    done < <(find "$APPLICATION_DIR" -type f -name '*.desktop' -print0 2>/dev/null)
fi

[ ${#names[@]} -eq 0 ] && exit 0

selection=$(printf '%s\n' "${names[@]}" | sort -u | fzf \
    --prompt="▶ " \
    --reverse \
    --info=hidden \
    --pointer=" " \
    --marker=" " \
    --cycle)

[ -z "$selection" ] && exit 0

cmd="${desktop_map[$selection]}"

# Ensure tmux session exists
tmux has-session -t "$TMUX_SESSION" 2>/dev/null || tmux new-session -d -s "$TMUX_SESSION"

# Run in background so it doesn't block the shell
tmux send-keys -t "$TMUX_SESSION" "$cmd & disown" C-m
