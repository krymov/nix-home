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
    sed -i 's/experimental-features = /experimental-features = flakes nix-command /' "$nix_conf"
  else
    echo 'experimental-features = nix-command flakes' >> "$nix_conf"
  fi
  ok "Flakes enabled"
else
  ok "Flakes already enabled"
fi

# Configure Attic binary cache
if ! grep -q 'attic.c1.aipe.dev' "$nix_conf" 2>/dev/null; then
  info "Adding Attic binary cache to $nix_conf"
  cat >> "$nix_conf" <<'CACHE'
extra-substituters = https://attic.c1.aipe.dev/aipe https://attic.c1.aipe.dev/mk
extra-trusted-public-keys = aipe:DrxqT6EJcO6J5+UPprEL+uN7wB7wQvxGMQ/hqCAIn7M= mk:iL0ONXTeRvlkgR8KSx65SkMFognIoV9+yoUwLRXHLMo=
CACHE
  ok "Attic binary cache configured"
else
  ok "Attic binary cache already configured"
fi

# Detect user
USERNAME="${USER:-$(whoami)}"
HOME_DIR="$HOME"
ok "User: $USERNAME ($HOME_DIR)"

# Select profile
printf '\n'
info "Available profiles:"
echo "  1) workspace   — full dotfiles, no GPG signing (default)"
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

# Generate a temporary flake that wraps nix-home with the local user
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat > "$tmpdir/flake.nix" <<FLAKE
{
  inputs = {
    nix-home.url = "${FLAKE_URL}";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nix-home/nixpkgs";
    };
  };

  outputs = { nix-home, home-manager, ... }: {
    homeConfigurations.default = home-manager.lib.homeManagerConfiguration {
      pkgs = import nix-home.inputs.nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;
        overlays = [ nix-home.overlays.unstable ];
      };
      modules = [
        nix-home.homeManagerModules.default
        {
          nix-home.profiles.${PROFILE}.enable = true;
          home = {
            username = "${USERNAME}";
            homeDirectory = "${HOME_DIR}";
            stateVersion = "25.11";
          };
        }
      ];
    };
  };
}
FLAKE

info "Activating home-manager with profile '$PROFILE'..."
nix run home-manager -- switch -b backup --flake "$tmpdir#default"
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
