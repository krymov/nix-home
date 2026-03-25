# Network diagnostics and testing tools.
{ pkgs }:

with pkgs; [
  mtr               # network diagnostic
  iperf3            # bandwidth testing (iperf)
  dnsutils          # dig + nslookup
  ldns              # drill command
  aria2             # download utility
  socat             # netcat replacement
  nmap              # network scanner
  ipcalc            # IP calculator
  doggo             # DNS lookup tool
  oha               # HTTP load testing
  trippy            # traceroute TUI
  swaks             # SMTP testing
  websocat          # WebSocket CLI
  grpcurl           # gRPC CLI client
  miniserve         # serve files over HTTP
]
