#!/bin/sh
# Focus-driven timewarrior. Keeps ONE interval per active PROJECT: re-tracks
# only when the project changes, so parallel projects (across sessions, or via
# cd within a pane) time-slice cleanly without micro-intervals.
#
# Usage: timew-focus.sh <session> [<path>]
# Called from the tmux client-session-changed hook and the zsh chpwd hook.
# Local-only (the laptop is the single source of truth); no-op inside ssh.
[ -z "${SSH_CONNECTION:-}" ] || exit 0
command -v timew >/dev/null 2>&1 || exit 0

session="${1:-}"
path="${2:-$PWD}"

# project = git repo root basename, else dir basename, else session name
proj=$( (cd "$path" 2>/dev/null && { git rev-parse --show-toplevel 2>/dev/null || pwd; }) | sed 's:.*/::' )
[ -n "$proj" ] || proj="${session:-misc}"

# If the active interval is already this project, do nothing (no churn).
if [ "$(timew get dom.active 2>/dev/null)" = "1" ]; then
  case "$(timew get dom.active.json 2>/dev/null)" in
    *"\"proj:$proj\""*) exit 0 ;;
  esac
fi

# Project changed (or nothing tracking) → start a fresh interval.
timew start "tmux:${session:-$proj}" "proj:$proj" >/dev/null 2>&1
