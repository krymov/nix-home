{ config, lib, ... }:

let
  p = config.nix-home.profiles;
  enabledCount = lib.count (x: x) [ p.personal.enable p.agent.enable p.dev-agent.enable p.server.enable p.workspace.enable ];
in {
  options.nix-home.profiles.server = {
    enable = lib.mkEnableOption "server profile (headless servers, minimal tooling)";
  };

  config = lib.mkIf p.server.enable {
    assertions = [{
      assertion = enabledCount == 1;
      message = "nix-home: exactly one profile must be active (got ${toString enabledCount})";
    }];

    nix-home.git = lib.mkDefault { enable = true; identity = "personal"; signing = false; };
    nix-home.zsh = lib.mkDefault { enable = true; };
    nix-home.tmux = lib.mkDefault { enable = true; };
    nix-home.nvim = lib.mkDefault { enable = true; minimal = true; };
    nix-home.ssh = lib.mkDefault { enable = true; };  # servers need to reach other infra
    nix-home.starship = lib.mkDefault { enable = true; };
    nix-home.cli-tools = lib.mkDefault { enable = true; direnv = false; };
  };
}
