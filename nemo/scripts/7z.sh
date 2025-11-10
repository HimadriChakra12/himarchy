#!/bin/bash
# Extract archive(s) into folders named after them
# Shows full 7z output (no suppression). If run from Nemo, will
# spawn a visible terminal to show extraction output.

# Ensure notifications work from Nemo
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
    export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
fi

notify() {
    notify-send -i package-x-generic "$1" "$2"
}

extract_file() {
    local file="$1"
    local outdir="${file%.*}"
    local name
    name="$(basename "$file")"

    mkdir -p "$outdir"
    notify "Extracting $name" "Extracting into '$outdir'..."

    # Decide whether to run in terminal
    if [ -t 1 ]; then
        # running in terminal — run extraction directly
        cmd=(7z x -o"$outdir" "$file")
        "${cmd[@]}"
        rc=$?
    else
        # not running in a terminal (likely Nemo) — spawn a terminal
        cmd_terminal=""
        if command -v alacritty >/dev/null 2>&1; then
            cmd_terminal="alacritty --title 7z -e bash -lc"
        elif command -v gnome-terminal >/dev/null 2>&1; then
            cmd_terminal="gnome-terminal -- bash -lc"
        elif command -v xterm >/dev/null 2>&1; then
            cmd_terminal="xterm -title 'Extracting $name' -e bash -lc"
        else
            # fallback — run directly
            cmd=(7z x -o"$outdir" "$file")
            "${cmd[@]}"
            rc=$?
            return
        fi

        # Command string to run inside terminal
        cmd_str="7z x -o\"$outdir\" \"$file\";"

        # Launch terminal
        eval "$cmd_terminal \"$cmd_str\""
        rc=$?
    fi

    if [ "$rc" -eq 0 ]; then
        notify "✅ Extraction complete" "'$name' extracted to '$outdir'"
    else
        notify "❌ Extraction failed" "Could not extract '$name' (exit $rc)"
    fi
}

# Main loop: handle all provided files
for file in "$@"; do
    [ -f "$file" ] || continue
    extract_file "$file"
done
