#!/bin/sh
# Memory usage percent for the tmux status bar. Prints e.g. "41%".
# Cross-platform (Linux /proc, macOS vm_stat). In a container this reflects
# the host's view of memory, which is acceptable for an at-a-glance chip.
case "$(uname -s)" in
  Linux)
    awk '/^MemTotal:/{t=$2} /^MemAvailable:/{a=$2} END{ if (t>0) printf "%d%%", (t-a)*100/t }' /proc/meminfo
    ;;
  Darwin)
    total=$(sysctl -n hw.memsize 2>/dev/null) || exit 0
    ps=$(sysctl -n hw.pagesize 2>/dev/null) || exit 0
    vm_stat 2>/dev/null | awk -v ps="$ps" -v total="$total" '
      /Pages active/            { gsub(/\./,"",$3); a=$3 }
      /Pages wired down/        { gsub(/\./,"",$4); w=$4 }
      /occupied by compressor/  { gsub(/\./,"",$5); c=$5 }
      END { used=(a+w+c)*ps; if (total>0) printf "%d%%", used*100/total }'
    ;;
esac
