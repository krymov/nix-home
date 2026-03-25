{ config, lib, ... }:

let
  p = config.nix-home.profiles;
  enabledCount = lib.count (x: x) [ p.personal.enable p.agent.enable p.dev-agent.enable p.server.enable ];
in {
  options.nix-home.profiles.agent = {
    enable = lib.mkEnableOption "agent profile (interactive coding agents, minimal tooling)";
  };

  config = lib.mkIf p.agent.enable {
    assertions = [{
      assertion = enabledCount == 1;
      message = "nix-home: exactly one profile must be active (got ${toString enabledCount})";
    }];

    # identity = "agent" resolves to: name = "Claude Agent", email = "agent@dalyoko.dev"
    nix-home.git = lib.mkDefault { enable = true; identity = "agent"; signing = false; };
    nix-home.zsh = lib.mkDefault { enable = true; };
    nix-home.tmux = lib.mkDefault { enable = true; };
    nix-home.nvim = lib.mkDefault { enable = true; minimal = true; };
    nix-home.ssh = lib.mkDefault { enable = true; };
    nix-home.starship = lib.mkDefault { enable = true; };
    nix-home.cli-tools = lib.mkDefault { enable = true; direnv = false; };
  };
}
