# System monitoring tools (primarily Linux/NixOS).
{ pkgs }:

with pkgs; [
  btop              # system monitor TUI
  lsof              # list open files
  lm_sensors        # hardware sensors
  smartmontools     # disk health (smartctl)
  powertop          # power consumption analyzer
  acpi              # battery/thermal info
]
++ pkgs.lib.optionals pkgs.stdenv.isLinux [
  iotop             # IO monitoring
  iftop             # network monitoring
  strace            # system call tracing
  ltrace            # library call tracing
  sysstat           # sar, iostat, etc.
  ethtool           # NIC configuration
  pciutils          # lspci
  usbutils          # lsusb
]
