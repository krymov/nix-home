{ config, lib, ... }:

let
  p = config.nix-home.profiles;
  enabledCount = lib.count (x: x) [ p.personal.enable p.agent.enable p.dev-agent.enable p.server.enable ];
in {
  options.nix-home.profiles.dev-agent = {
    enable = lib.mkEnableOption "dev-agent profile (agents with full dev environment)";
  };

  config = lib.mkIf p.dev-agent.enable {
    assertions = [{
      assertion = enabledCount == 1;
      message = "nix-home: exactly one profile must be active (got ${toString enabledCount})";
    }];

    # Full dev environment but with generic agent identity
    nix-home.git = lib.mkDefault { enable = true; identity = "agent"; signing = false; };
    nix-home.zsh = lib.mkDefault { enable = true; };
    nix-home.tmux = lib.mkDefault { enable = true; };
    nix-home.nvim = lib.mkDefault { enable = true; };  # full LSP
    nix-home.ssh = lib.mkDefault { enable = true; };
    nix-home.starship = lib.mkDefault { enable = true; };
    nix-home.cli-tools = lib.mkDefault { enable = true; };  # includes direnv
  };
}
