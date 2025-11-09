#!/bin/bash

SESSION_NAME="cmus"

# Try to detect the default terminal emulator
if command -v alacritty >/dev/null 2>&1; then
    TERMINAL="alacritty"
fi

# Create or attach to the cmus session
if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    "$TERMINAL" -e tmux new-session -s "$SESSION_NAME" cmus
else
    "$TERMINAL" -e tmux attach -t "$SESSION_NAME"
fi
