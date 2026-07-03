#!/bin/sh
# Active AWS identity (assumed profile / aws-vault session), or nothing.
# Region is intentionally ignored — the profile is the blast-radius signal.
printf '%s' "${AWS_VAULT:-${AWS_PROFILE:-}}"
