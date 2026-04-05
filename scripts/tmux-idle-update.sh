#!/usr/bin/env bash
# Batch update all window tab colors based on idle time.
# Called once per status-interval from status-right.
# Colors passed via IDLE_COLOR_0..7 env vars from Nix config.

ACTIVITY_DIR="${HOME}/.tmux/activity"
mkdir -p "$ACTIVITY_DIR"

NOW=$(date +%s)
SESSION=$(tmux display-message -p '#{session_name}')
ACTIVE_WIN=$(tmux display-message -p '#{window_id}')

while IFS='|' read -r win_id win_idx win_name win_flags bell_flag; do
    [[ "$win_id" == "$ACTIVE_WIN" ]] && continue

    # Read activity timestamp
    activity_file="${ACTIVITY_DIR}/${win_id//[@%]/}"
    if [[ -f "$activity_file" ]]; then
        last_activity=$(< "$activity_file")
        idle_secs=$((NOW - last_activity))
    else
        idle_secs=99999
    fi

    # Map idle time to color tier
    if (( idle_secs < 600 )); then
        color="$IDLE_COLOR_0"
    elif (( idle_secs < 1800 )); then
        color="$IDLE_COLOR_1"
    elif (( idle_secs < 3600 )); then
        color="$IDLE_COLOR_2"
    elif (( idle_secs < 7200 )); then
        color="$IDLE_COLOR_3"
    elif (( idle_secs < 14400 )); then
        color="$IDLE_COLOR_4"
    elif (( idle_secs < 28800 )); then
        color="$IDLE_COLOR_5"
    elif (( idle_secs < 86400 )); then
        color="$IDLE_COLOR_6"
    else
        color="$IDLE_COLOR_7"
    fi

    # Bell override: bold
    if [[ "$bell_flag" == "1" ]]; then
        style="fg=$color,bg=default,bold"
    else
        style="fg=$color,bg=default"
    fi

    # Strip activity '#' flag from display
    win_flags="${win_flags//#/}"

    tmux set-window-option -t "$win_id" window-status-format \
        "#[$style] ${win_idx}:${win_name}${win_flags} " 2>/dev/null
done < <(tmux list-windows -t "$SESSION" -F '#{window_id}|#{window_index}|#{window_name}|#{window_flags}|#{window_bell_flag}')

# Throttled orphan cleanup (every 60s)
cleanup_marker="${ACTIVITY_DIR}/.last_cleanup"
do_cleanup=0
if [[ -f "$cleanup_marker" ]]; then
    last_cleanup=$(< "$cleanup_marker")
    (( NOW - last_cleanup > 60 )) && do_cleanup=1
else
    do_cleanup=1
fi

if (( do_cleanup )); then
    echo "$NOW" > "$cleanup_marker"
    declare -A valid
    while read -r wid; do
        valid["${wid//[@%]/}"]=1
    done < <(tmux list-windows -a -F '#{window_id}')

    for f in "$ACTIVITY_DIR"/*; do
        [[ -f "$f" ]] || continue
        fname=$(basename "$f")
        [[ "$fname" == .* ]] && continue
        if [[ -z "${valid[$fname]+x}" ]]; then
            rm -f "$f"
        fi
    done
fi
