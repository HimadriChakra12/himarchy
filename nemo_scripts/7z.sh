#!/bin/bash
# Extract archive(s) into folders named after them, optionally using a password
# Supports Zenity first, Alacritty fallback, auto-timeout after 1 minute

notify() {
    notify-send -i package-x-generic "$1" "$2"
}

ask_password() {
    local name="$1"
    local password=""

    if command -v zenity >/dev/null 2>&1; then
        password=$(zenity --password --title="Password required" --text="Enter password for '$name':")
    else
        # Use a working terminal (Alacritty preferred, else fallback)
        if command -v alacritty >/dev/null 2>&1; then
            term_cmd="alacritty"
        elif command -v gnome-terminal >/dev/null 2>&1; then
            term_cmd="gnome-terminal -- bash -c"
        elif command -v xterm >/dev/null 2>&1; then
            term_cmd="xterm -e"
        else
            echo "No terminal found for password input!" >&2
            return
        fi

        tmpfile=$(mktemp)

        # Launch terminal to read password with 1-minute timeout
        bash -c "
            read -t 60 -rsp 'Enter password for \"$name\" (leave empty to skip): ' pass
            echo
            echo \"\$pass\" > '$tmpfile'
        " &

        if [[ "$term_cmd" == "alacritty" ]]; then
            alacritty -e bash -c "read -t 8 -rsp 'Enter password for \"$name\" (leave empty to skip): ' pass; echo; echo \"\$pass\" > '$tmpfile'"
        else
            $term_cmd "read -t 60 -rsp 'Enter password for \"$name\" (leave empty to skip): ' pass; echo; echo \"\$pass\" > '$tmpfile'; read -n 1"
        fi

        # Wait for temp file to appear or timeout
        SECONDS=0
        while [ ! -f "$tmpfile" ] && [ $SECONDS -lt 65 ]; do sleep 0.1; done
        [ -f "$tmpfile" ] && password=$(<"$tmpfile")
        rm -f "$tmpfile"
    fi

    echo "$password"
}

extract_file() {
    local file="$1"
    local outdir="${file%.*}"
    local name
    name="$(basename "$file")"

    mkdir -p "$outdir"
    notify "Extracting $name" "Extracting into '$outdir'..."

    # Ask for password
    password="$(ask_password "$name")"

    # Build 7z command
    cmd=(7z x -bsp1 -bso0 -o"$outdir" "$file")
    [ -n "$password" ] && cmd+=("-p$password")

    # Run extraction
    (
        "${cmd[@]}" | while IFS= read -r line; do
            perc=$(grep -o '[0-9]\+%' <<< "$line" | tr -d '%')
            [ -n "$perc" ] && notify "Extracting $name" "$perc% complete..."
        done
    )

    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        notify "Extraction complete" "'$name' extracted to '$outdir'"
    else
        notify "Extraction failed" "Could not extract '$name'"
    fi
}

# Main loop
for file in "$@"; do
    [ -f "$file" ] || continue
    extract_file "$file"
done
