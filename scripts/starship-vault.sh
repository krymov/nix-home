#!/bin/sh
# Vault / OpenBao host (scheme + port stripped), or nothing.
a="${BAO_ADDR:-${VAULT_ADDR:-}}"
[ -n "$a" ] || exit 0
a="${a#*://}"          # drop scheme
printf '%s' "${a%%:*}" # drop :port
