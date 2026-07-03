#!/bin/sh
# Active gcloud project, or nothing. Reads config files only (no network).
if [ -n "${CLOUDSDK_CORE_PROJECT:-}" ]; then
  printf '%s' "$CLOUDSDK_CORE_PROJECT"; exit 0
fi
dir="${CLOUDSDK_CONFIG:-$HOME/.config/gcloud}"
c=$(cat "$dir/active_config" 2>/dev/null) || exit 0
[ -n "$c" ] || exit 0
sed -n 's/^project *= *//p' "$dir/configurations/config_$c" 2>/dev/null | head -1 | tr -d '\n'
