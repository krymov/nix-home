# Core CLI essentials — always installed on every host and dotfiles environment.
{ pkgs }:

with pkgs; [
  # Shell & terminal
  zsh
  tmux

  # Search & navigation
  ripgrep
  fd
  fzf
  bat
  eza

  # Data formats (lightweight)
  jq
  yq-go

  # Version control
  git
  lazygit
  gh
  tea

  # File management
  tree
  yazi

  # Utilities
  curl
  wget
  htop
  just
  direnv
  stow
  wakeonlan
  unixtools.watch

  # Text processing
  sd                # intuitive sed replacement
  delta             # better diffs
  markdownlint-cli2 # markdown linting (nvim conform + nvim-lint)

  # Security / crypto
  age
  agenix
  gnupg
  yubikey-manager
  openssl

  # Web browsing (terminal)
  w3m
  browsh

  # IRC / chat
  halloy

  # Nix
  nix-search-cli

  # Email
  aerc

  # Fonts
  nerd-fonts.jetbrains-mono
  nerd-fonts.fira-code
  nerd-fonts.hack
  nerd-fonts.meslo-lg
]
