#!/usr/bin/env bash
# Receives piped pane output and updates activity timestamp.
# Called by pipe-pane with window_id as argument.
# Throttled to 1 write/second.

WINDOW_ID="$1"
ACTIVITY_DIR="${HOME}/.tmux/activity"
ACTIVITY_FILE="${ACTIVITY_DIR}/${WINDOW_ID//[@%]/}"

mkdir -p "$ACTIVITY_DIR"

last_update=0
while IFS= read -r _line; do
    now=$(date +%s)
    if (( now > last_update )); then
        echo "$now" > "$ACTIVITY_FILE"
        last_update=$now
    fi
done
