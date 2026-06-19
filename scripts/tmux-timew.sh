#!/bin/sh
# Timewarrior chip: active task + elapsed (H:MM). Prints nothing when idle.
# Styled with THM_FG/THM_BG (passed from tmux as theme colors); the emitted
# #[...] sequences are interpreted by tmux. Pairs with the per-session
# `timew start tmux:<session>` hook in tmux.nix.
command -v timew >/dev/null 2>&1 || exit 0
[ "$(timew get dom.active 2>/dev/null)" = "1" ] || exit 0

tag=$(timew get dom.active.tag.1 2>/dev/null | tr -d '"')
tag=${tag#tmux:}                                    # drop the auto-tag prefix
dur=$(timew get dom.active.duration 2>/dev/null)    # ISO 8601, e.g. PT1H24M7S
h=$(printf '%s' "$dur" | sed -nE 's/.*PT([0-9]+)H.*/\1/p'); h=${h:-0}
m=$(printf '%s' "$dur" | sed -nE 's/.*[PTH]([0-9]+)M.*/\1/p'); m=${m:-0}

printf '#[fg=%s,bg=%s,bold] ⏱ %s %d:%02d #[default]' \
  "${THM_FG:-default}" "${THM_BG:-default}" "${tag:-timew}" "$h" "$m"
