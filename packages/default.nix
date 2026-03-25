# Shared package registry — single source of truth for all hosts and dotfiles.
#
# Usage (NixOS module):
#   let sharedPkgs = import inputs.nix-home + "/packages" { inherit pkgs; };
#   in { environment.systemPackages = sharedPkgs.core ++ sharedPkgs.dev; }
#
# Usage (home-manager):
#   let sharedPkgs = import inputs.nix-home + "/packages" { inherit pkgs; };
#   in { home.packages = sharedPkgs.core ++ sharedPkgs.networking; }

{ pkgs }:

{
  core         = import ./core.nix         { inherit pkgs; };
  dev          = import ./dev.nix          { inherit pkgs; };
  data         = import ./data.nix         { inherit pkgs; };
  cloud        = import ./cloud.nix        { inherit pkgs; };
  productivity = import ./productivity.nix { inherit pkgs; };
  networking   = import ./networking.nix   { inherit pkgs; };
  monitoring   = import ./monitoring.nix   { inherit pkgs; };
}
