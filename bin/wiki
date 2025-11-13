#!/bin/bash

CACHE_DIR="$HOME/.cache/wiki-tui"
mkdir -p "$CACHE_DIR"

search_term="$1"

fetch_cache() {
    local title="$1"
    local safe_title=$(echo "$title" | tr ' /' '__')
    local cache_file="$CACHE_DIR/$safe_title.txt"

    if [[ ! -f "$cache_file" ]]; then
        url_title=$(echo "$title" | sed 's/ /%20/g')
        page_json=$(curl -s "https://en.wikipedia.org/w/api.php?action=query&prop=extracts&explaintext&titles=$url_title&format=json")
        page_content=$(echo "$page_json" | jq -r '.query.pages | to_entries[0].value.extract')
        echo "$page_content" > "$cache_file"
    fi
}

export -f fetch_cache
export CACHE_DIR

titles=$(curl -s "https://en.wikipedia.org/w/api.php?action=query&list=search&srsearch=$search_term&format=json" \
    | jq -r '.query.search[:10][] | .title')

# Corrected parallel fetch
echo "$titles" | xargs -P5 -I{} bash -c 'fetch_cache "$@"' _ {}

# fzf with cached preview
selected=$(echo "$titles" | fzf --height=40% --border --prompt="Wiki Search> ")

if [[ -n "$selected" ]]; then
    tmpfile=$(mktemp /tmp/wiki_article.XXXXXX.txt)
    cat "$CACHE_DIR/$(echo $selected | tr ' /' '__').txt" > "$tmpfile"
    nvim "$tmpfile" -c ReaderMode
fi
