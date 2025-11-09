#!/bin/bash
# Extract archive(s) into folders named after them, with desktop notifications

notify() {
    notify-send -i package-x-generic "$1" "$2"
}

for file in "$@"; do
    [ -f "$file" ] || continue
    outdir="${file%.*}"
    mkdir -p "$outdir"

    name="$(basename "$file")"
    notify "Extracting $name" "Extracting into '$outdir'..."

    # Run extraction and capture progress
    total=$(7z l "$file" | grep -E '^[0-9]+ files' | awk '{print $1}')
    [ -z "$total" ] && total=0

    (
        7z x -bsp1 -bso0 -o"$outdir" "$file" | while IFS= read -r line; do
            # Example line: " 23% ..."
            perc=$(grep -o '[0-9]\+%' <<< "$line" | tr -d '%')
            [ -n "$perc" ] && notify "Extracting $name" "$perc% complete..."
        done
    )

    if [ $? -eq 0 ]; then
        notify "✅ Extraction complete" "'$name' extracted to '$outdir'"
    else
        notify "❌ Extraction failed" "Could not extract '$name'"
    fi
done

