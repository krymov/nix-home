{ config, lib, pkgs, ... }:

let cfg = config.nix-home.ssh;
in {
  options.nix-home.ssh = {
    enable = lib.mkEnableOption "SSH configuration";
    extraSettings = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Additional SSH settings to merge (for private host definitions)";
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

      settings = {
        # Public git forges
        "github.com" = { HostName = "github.com"; User = "git"; };
        "gitlab.com" = { HostName = "gitlab.com"; User = "git"; };

        # Global defaults
        "*" = {
          IdentityFile = "~/.ssh/id_ed25519";
          IdentitiesOnly = "yes";
          AddKeysToAgent = "yes";
          ServerAliveInterval = 60;
          ServerAliveCountMax = 3;
        } // lib.optionalAttrs pkgs.stdenv.isDarwin {
          UseKeychain = "yes";
        };
      } // cfg.extraSettings;
    };
  };
}
