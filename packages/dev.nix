# Development tools — language runtimes, editors, and dev tooling.
{ pkgs }:

with pkgs; [
  # Editors (neovim managed via programs.neovim in home.nix)
  vim
  vscode

  # Nix tooling
  cachix
  nix-direnv

  # Python
  python312
  uv
  ruff
  pipx
  python3Packages.virtualenv

  # Node.js
  nodejs_22
  pnpm
  nodePackages.typescript
  nodePackages.eslint
  nodePackages.prettier

  # Rust
  rustup
  cargo-edit
  cargo-watch
  cargo-make
  cargo-audit

  # Go
  go
  golangci-lint
  gopls
  delve

  # C/C++
  clang
  libiconv

  # Tree-sitter
  tree-sitter

  # Documentation / publishing
  typst
  pandoc
  texliveFull
  hugo
  poetry

  # Dev utilities
  hurl
  grex              # generate regex from examples
  gitleaks          # git secrets scanner
  infisical         # secrets management
  claude-code       # Claude in your terminal
  hyperfine         # benchmark CLI commands

  # Platform CLIs
  temporal-cli      # Temporal workflow management
  svix-cli          # Svix webhooks CLI

  # .NET (if needed)
  dotnet-sdk_8

  # Ethereum / blockchain dev
  go-ethereum
]
