#!/bin/bash
APPLICATION_DIR="$HOME/.local/share/applications"
CACHE_DIR="$HOME/.cache"
CACHE_FILE="$CACHE_DIR/app_launcher_cache"
HIST_FILE="$CACHE_DIR/file_search_history"
TMUX_SESSION="apps"
MAX_HISTORY=5

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

# --- Background refresh if stale ---
if [[ ! -f "$CACHE_FILE" ]]; then
    update_cache_bg
else
    last_update=$(stat -c %Y "$CACHE_FILE" 2>/dev/null)
    now=$(date +%s)
    if (( now - last_update > 60 )) || find "$APPLICATION_DIR" -type f -name '*.desktop' -newer "$CACHE_FILE" | grep -q .; then
        update_cache_bg
    fi
fi

# --- Exit early if cache empty ---
if [ ${#names[@]} -eq 0 ]; then
    echo "Building cache..."
    update_cache_bg
    exit 0
fi

# --- Main unified fzf launcher ---
selection=$(printf '%s\n' "${names[@]}" | sort -u | fzf \
    --prompt="▶ " \
    --reverse \
    --info=hidden \
    --pointer=" " \
    --marker=" " \
    --cycle \
    --print-query)

query=$(echo "$selection" | head -n1)
choice=$(echo "$selection" | tail -n1)

# --- Handle special prefixes ---

if [[ "$query" == '$>' ]]; then
    # --- RECENT FILE SEARCH HISTORY ---
    if [[ ! -f "$HIST_FILE" ]]; then
        notify-send "No recent file searches yet."
        exit 0
    fi

    mapfile -t recent < <(tac "$HIST_FILE" | sed "s|^$HOME|~|")
    selected=$(printf '%s\n' "${recent[@]}" | fzf --prompt="Recent $: " --reverse --info=hidden)
    [[ -z "$selected" ]] && exit 0

    search_root="${selected/#\~/$HOME}"
    result=$(find "$search_root" -type f 2>/dev/null | sed "s|^$HOME|~|" | fzf --prompt="🔍 File: " --reverse --info=hidden)
    result="${result/#\~/$HOME}"
    [ -n "$result" ] && xdg-open "$result" >/dev/null 2>&1 &
    exit 0

elif [[ "$query" == \$* ]]; then
    # --- NORMAL FILE SEARCH ---
    search_arg="${query:1}"
    search_arg="${search_arg#"${search_arg%%[![:space:]]*}"}"
    search_arg="${search_arg%"${search_arg##*[![:space:]]}"}"

    if [[ -z "$search_arg" ]]; then
        search_root="$HOME"
    elif [[ "$search_arg" == ~* ]]; then
        search_root="$search_arg"
    elif [[ "$search_arg" == /* ]]; then
        search_root="$search_arg"
    elif [[ "$search_arg" == .* ]]; then
        search_root="$HOME/$search_arg"
    else
        search_root="$HOME/$search_arg"
    fi

    search_root="${search_root/#\~/$HOME}"
    [[ ! -d "$search_root" ]] && search_root="$HOME"

    # --- Save to history ---
    grep -vFx "$search_root" "$HIST_FILE" 2>/dev/null | tail -n "$((MAX_HISTORY-1))" > "$HIST_FILE.tmp"
    printf '%s\n' "$search_root" >> "$HIST_FILE.tmp"
    mv "$HIST_FILE.tmp" "$HIST_FILE"

    result=$(find "$search_root" -type f 2>/dev/null | sed "s|^$HOME|~|" | fzf --prompt="🔍 File: " --reverse --info=hidden)
    result="${result/#\~/$HOME}"
    [ -n "$result" ] && xdg-open "$result" >/dev/null 2>&1 &
    exit 0

elif [[ "$query" == %* ]]; then
    # --- WINDOW SEARCH MODE ---
    if command -v hyprctl >/dev/null 2>&1; then
        mapfile -t windows < <(hyprctl clients -j | jq -r '.[] | "\(.class) - \(.title)"')
        selected=$(printf '%s\n' "${windows[@]}" | fzf --prompt="🪟 Window: " --reverse --info=hidden)
        if [[ -n "$selected" ]]; then
            win_title="${selected#*- }"
            hyprctl dispatch focuswindow title:"$win_title"
        fi
    elif command -v wmctrl >/dev/null 2>&1; then
        mapfile -t windows < <(wmctrl -lx | awk '{ $3=""; print $2 " - " substr($0, index($0,$4)) }')
        selected=$(printf '%s\n' "${windows[@]}" | fzf --prompt="🪟 Window: " --reverse --info=hidden)
        if [[ -n "$selected" ]]; then
            win_title="${selected#*- }"
            wmctrl -a "$win_title"
        fi
    else
        notify-send "Window search not supported (no hyprctl/wmctrl)"
    fi
    exit 0

else
    # --- APPLICATION MODE ---
    [ -z "$choice" ] && exit 0
    cmd="${desktop_map[$choice]}"
    tmux has-session -t "$TMUX_SESSION" 2>/dev/null || tmux new-session -d -s "$TMUX_SESSION"
    tmux send-keys -t "$TMUX_SESSION" "$cmd & disown" C-m
fi
