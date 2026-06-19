{ config, lib, ... }:

let cfg = config.nix-home;
in {
  options.nix-home.environment = lib.mkOption {
    type = lib.types.enum [ "dev" "staging" "prod" ];
    default = "dev";
    description = ''
      Deployment blast-radius for this host. Single source of truth for the
      danger signal: exported as HOST_ENV (consumed by the starship prompt) and
      surfaced as the tmux @host_env user option. Set per-host in the flake.
    '';
  };

  config = {
    home.sessionVariables.HOST_ENV = cfg.environment;
  };
}
