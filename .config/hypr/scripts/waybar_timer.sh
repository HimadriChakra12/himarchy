#!/bin/bash

TIMER_FILE="/tmp/waybar_timer_seconds"
STATE_FILE="/tmp/waybar_timer_state"
SESSION_NAME="waybar_timer_session"

# Menu in Alacritty via fzf
CHOICE=$(echo -e "Pause/Resume\nStop timer\n40 min\n60 min\n90 min\nCustom" | fzf --prompt="Select timer: ")
[ -z "$CHOICE" ] && exit 0

# Pause / Resume
if [ "$CHOICE" == "Pause/Resume" ]; then
    if tmux has-session -t $SESSION_NAME 2>/dev/null; then
        if [ "$(cat $STATE_FILE 2>/dev/null)" == "paused" ]; then
            echo "running" > $STATE_FILE
            notify-send "Timer resumed" "Your timer is now running."
        else
            echo "paused" > $STATE_FILE
            notify-send "Timer paused" "Your timer is paused."
        fi
    else
        notify-send "No timer" "No active timer to pause/resume."
    fi
    exit 0
fi

# Stop timer
if [ "$CHOICE" == "Stop timer" ]; then
    if tmux has-session -t $SESSION_NAME 2>/dev/null; then
        tmux kill-session -t $SESSION_NAME
    fi
    echo 0 > "$TIMER_FILE"
    rm -f "$STATE_FILE"
    notify-send "Timer stopped" "Your timer has been stopped."
    exit 0
fi

# Start a new timer
case "$CHOICE" in
    "40 min") MINUTES=40 ;;
    "60 min") MINUTES=60 ;;
    "90 min") MINUTES=90 ;;
    "Custom") read -rp "Enter minutes: " MINUTES ;;
    *) exit 1 ;;
esac

TOTAL_SECONDS=$((MINUTES*60))

# Kill previous session if exists
if tmux has-session -t $SESSION_NAME 2>/dev/null; then
    tmux kill-session -t $SESSION_NAME
fi

# Start countdown in background tmux session
tmux new-session -d -s $SESSION_NAME bash -c "
    SECONDS_LEFT=$TOTAL_SECONDS
    echo \$SECONDS_LEFT > $TIMER_FILE
    echo 'running' > $STATE_FILE

    while [ \$SECONDS_LEFT -gt 0 ]; do
        STATE=\$(cat $STATE_FILE 2>/dev/null)
        if [ \"\$STATE\" == 'running' ]; then
            sleep 1
            SECONDS_LEFT=\$((SECONDS_LEFT - 1))
            echo \$SECONDS_LEFT > $TIMER_FILE
        else
            sleep 1
        fi
    done

    echo 0 > $TIMER_FILE
    rm -f $STATE_FILE
    notify-send 'Timer done!' 'Your $MINUTES-minute timer has finished.'
"
