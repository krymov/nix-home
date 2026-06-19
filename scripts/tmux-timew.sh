#!/bin/sh
# Timewarrior chip: active project + elapsed (H:MM). Prints nothing when idle.
# Styled with THM_FG/THM_BG (theme colors from tmux); emitted #[...] is
# interpreted by tmux. Labels by the proj: tag, falling back to the first tag.
command -v timew >/dev/null 2>&1 || exit 0
[ "$(timew get dom.active 2>/dev/null)" = "1" ] || exit 0

json=$(timew get dom.active.json 2>/dev/null)
label=$(printf '%s' "$json" | grep -oE '"proj:[^"]+"' | head -1 | sed 's/"//g; s/proj://')
[ -n "$label" ] || label=$(printf '%s' "$json" | sed -nE 's/.*"tags":\["([^"]+)".*/\1/p' | sed 's/^tmux://')

dur=$(timew get dom.active.duration 2>/dev/null)    # ISO 8601, e.g. PT1H24M7S
h=$(printf '%s' "$dur" | sed -nE 's/.*PT([0-9]+)H.*/\1/p'); h=${h:-0}
m=$(printf '%s' "$dur" | sed -nE 's/.*[PTH]([0-9]+)M.*/\1/p'); m=${m:-0}

printf '#[fg=%s,bg=%s,bold] ⏱ %s %d:%02d #[default]' \
  "${THM_FG:-default}" "${THM_BG:-default}" "${label:-timew}" "$h" "$m"
