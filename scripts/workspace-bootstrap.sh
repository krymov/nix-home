#!/usr/bin/env bash
set -euo pipefail

FLAKE_URL="github:krymov/nix-home"
PROFILE="workspace"

info()  { printf '\033[1;34m→\033[0m %s\n' "$*"; }
ok()    { printf '\033[1;32m✓\033[0m %s\n' "$*"; }
err()   { printf '\033[1;31m✗\033[0m %s\n' "$*" >&2; }

# Check nix is available
if ! command -v nix >/dev/null 2>&1; then
  err "nix not found. Install it first: https://nixos.org/download"
  exit 1
fi
ok "nix found: $(nix --version)"

# Enable flakes if not already configured
nix_conf="${XDG_CONFIG_HOME:-$HOME/.config}/nix/nix.conf"
if ! nix show-config 2>/dev/null | grep -q 'flakes'; then
  info "Enabling flakes in $nix_conf"
  mkdir -p "$(dirname "$nix_conf")"
  if [[ -f "$nix_conf" ]] && grep -q 'experimental-features' "$nix_conf"; then
    # Append flakes to existing line
    sed -i 's/experimental-features = /experimental-features = flakes nix-command /' "$nix_conf"
  else
    echo 'experimental-features = nix-command flakes' >> "$nix_conf"
  fi
  ok "Flakes enabled"
else
  ok "Flakes already enabled"
fi

# Select profile
printf '\n'
info "Available profiles:"
echo "  1) workspace   — personal identity, full dotfiles, no GPG signing (default)"
echo "  2) personal    — full environment with GPG signing"
echo "  3) agent       — minimal tooling, agent identity"
echo "  4) dev-agent   — full dev environment, agent identity"
echo "  5) server      — headless server, minimal tooling"
printf '\n'
read -rp "Select profile [1]: " choice
case "${choice:-1}" in
  1) PROFILE="workspace" ;;
  2) PROFILE="personal" ;;
  3) PROFILE="agent" ;;
  4) PROFILE="dev-agent" ;;
  5) PROFILE="server" ;;
  *) err "Invalid choice"; exit 1 ;;
esac
ok "Using profile: $PROFILE"

# Run home-manager switch
info "Activating home-manager with profile '$PROFILE'..."
nix run home-manager -- switch -b backup --flake "${FLAKE_URL}#${PROFILE}"
ok "Home Manager activated"

# Switch shell to zsh if not already
current_shell=$(basename "$SHELL")
if [[ "$current_shell" != "zsh" ]]; then
  hm_zsh="$HOME/.nix-profile/bin/zsh"
  if [[ -x "$hm_zsh" ]]; then
    info "Default shell is $current_shell. Switch to zsh?"
    read -rp "Change default shell to zsh? [Y/n]: " yn
    if [[ "${yn:-y}" =~ ^[Yy]$ ]]; then
      if grep -qx "$hm_zsh" /etc/shells 2>/dev/null; then
        chsh -s "$hm_zsh"
        ok "Default shell changed to zsh"
      else
        info "Add $hm_zsh to /etc/shells first (needs sudo):"
        echo "  echo '$hm_zsh' | sudo tee -a /etc/shells && chsh -s '$hm_zsh'"
      fi
    fi
  fi
fi

printf '\n'
ok "Done! Start a new shell to apply:"
echo "  exec zsh"
