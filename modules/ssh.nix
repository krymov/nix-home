{ config, lib, pkgs, ... }:

let cfg = config.nix-home.ssh;
in {
  options.nix-home.ssh = {
    enable = lib.mkEnableOption "SSH configuration";
    extraMatchBlocks = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Additional SSH matchBlocks to merge (for private host definitions)";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      includes = [ "~/.ssh/config.local" ];

      extraConfig = ''
        IPQoS none
        SetEnv LANG=en_US.UTF-8
        SendEnv -LC_*
      '';

      matchBlocks = {
        # Public git forges
        "github.com" = { hostname = "github.com"; user = "git"; };
        "gitlab.com" = { hostname = "gitlab.com"; user = "git"; };

        # Global defaults
        "*" = {
          identityFile = "~/.ssh/id_ed25519";
          extraOptions = {
            IdentitiesOnly = "yes";
            AddKeysToAgent = "yes";
            ServerAliveInterval = "60";
            ServerAliveCountMax = "3";
          } // lib.optionalAttrs pkgs.stdenv.isDarwin {
            UseKeychain = "yes";
          };
        };
      } // cfg.extraMatchBlocks;
    };
  };
}
