{ config, lib, ... }:

let
  p = config.nix-home.profiles;
  enabledCount = lib.count (x: x) [ p.personal.enable p.agent.enable p.dev-agent.enable p.server.enable p.workspace.enable ];
in {
  options.nix-home.profiles.workspace = {
    enable = lib.mkEnableOption "workspace profile (cloud workspace with existing tooling, personal identity, no GPG)";
  };

  config = lib.mkIf p.workspace.enable {
    assertions = [{
      assertion = enabledCount == 1;
      message = "nix-home: exactly one profile must be active (got ${toString enabledCount})";
    }];

    nix-home.git = lib.mkDefault { enable = true; identity = "personal"; signing = false; };
    nix-home.zsh = lib.mkDefault { enable = true; };
    nix-home.tmux = lib.mkDefault { enable = true; catppuccinFlavor = "frappe"; };
    nix-home.tmux-idle = lib.mkDefault { enable = true; };
    nix-home.nvim = lib.mkDefault { enable = true; };
    nix-home.ssh = lib.mkDefault { enable = true; };
    nix-home.starship = lib.mkDefault { enable = true; };
    nix-home.cli-tools = lib.mkDefault { enable = true; };
  };
}
