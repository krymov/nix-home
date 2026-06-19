#!/bin/sh
# Battery chip: prints nothing when no battery exists — so it disappears on
# desktops, VMs, k8s containers and servers, and only shows on laptops.
# Styled with THM_FG/THM_BG; emitted #[...] is interpreted by tmux.
pct=""
case "$(uname -s)" in
  Darwin)
    out=$(pmset -g batt 2>/dev/null)
    printf '%s' "$out" | grep -q "InternalBattery" || exit 0
    pct=$(printf '%s' "$out" | sed -nE 's/.*[^0-9]([0-9]+)%.*/\1/p')
    ;;
  Linux)
    bat=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1)
    [ -n "$bat" ] || exit 0
    pct=$(cat "$bat/capacity" 2>/dev/null)
    ;;
  *) exit 0 ;;
esac
[ -n "$pct" ] || exit 0

if   [ "$pct" -ge 80 ]; then icon=""
elif [ "$pct" -ge 50 ]; then icon=""
elif [ "$pct" -ge 20 ]; then icon=""
else                         icon=""
fi
printf '#[fg=%s,bg=%s,bold] %s %s%% #[default]' \
  "${THM_FG:-default}" "${THM_BG:-default}" "$icon" "$pct"
