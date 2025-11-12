#!/bin/bash
APPLICATION_DIR="$HOME/.local/share/applications"
CACHE_DIR="$HOME/.cache"
CACHE_FILE="$CACHE_DIR/app_launcher_cache"
TMUX_SESSION="apps"

mkdir -p "$CACHE_DIR"

declare -A desktop_map
names=()

# --- Fast cache load ---
if [[ -f "$CACHE_FILE" ]]; then
    while IFS='|' read -r name cmd; do
        [[ -z "$name" || -z "$cmd" ]] && continue
        names+=("$name")
        desktop_map["$name"]="$cmd"
    done < "$CACHE_FILE"
fi

# --- Background cache updater ---
update_cache_bg() {
    (
        tmpfile=$(mktemp)
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

            printf '%s|%s\n' "$name" "$exec_cmd" >> "$tmpfile"
        done
        mv "$tmpfile" "$CACHE_FILE"
    ) >/dev/null 2>&1 &
}

# --- Check if cache missing or outdated, trigger bg refresh ---
if [[ ! -f "$CACHE_FILE" ]]; then
    update_cache_bg
else
    last_update=$(stat -c %Y "$CACHE_FILE" 2>/dev/null)
    now=$(date +%s)
    # Update if cache older than 60s or any .desktop file newer
    if (( now - last_update > 10 )) || find "$APPLICATION_DIR" -type f -name '*.desktop' -newer "$CACHE_FILE" | grep -q .; then
        update_cache_bg
    fi
fi

# --- Exit early if no cache entries yet ---
[ ${#names[@]} -eq 0 ] && echo "Building cache..." && update_cache_bg && exit 0

# --- FZF selection ---
selection=$(printf '%s\n' "${names[@]}" | sort -u | fzf \
    --prompt="▶ " \
    --reverse \
    --info=hidden \
    --pointer=" " \
    --marker=" " \
    --cycle)

[ -z "$selection" ] && exit 0

cmd="${desktop_map[$selection]}"

# --- Run command safely in tmux background ---
tmux has-session -t "$TMUX_SESSION" 2>/dev/null || tmux new-session -d -s "$TMUX_SESSION"
tmux send-keys -t "$TMUX_SESSION" "$cmd & disown" C-m
