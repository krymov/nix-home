{ config, lib, ... }:

let
  p = config.nix-home.profiles;
  enabledCount = lib.count (x: x) [ p.personal.enable p.agent.enable p.dev-agent.enable p.server.enable ];
in {
  options.nix-home.profiles.personal = {
    enable = lib.mkEnableOption "personal profile (full environment for Mark)";
  };

  config = lib.mkIf p.personal.enable {
    assertions = [{
      assertion = enabledCount == 1;
      message = "nix-home: exactly one profile must be active (got ${toString enabledCount})";
    }];

    nix-home.git = lib.mkDefault { enable = true; identity = "personal"; signing = true; signingKey = "BDC056D14D93DCE8"; };
    nix-home.zsh = lib.mkDefault { enable = true; };
    nix-home.tmux = lib.mkDefault { enable = true; };
    nix-home.nvim = lib.mkDefault { enable = true; };
    nix-home.ssh = lib.mkDefault { enable = true; };
    nix-home.starship = lib.mkDefault { enable = true; };
    nix-home.cli-tools = lib.mkDefault { enable = true; };
  };
}
