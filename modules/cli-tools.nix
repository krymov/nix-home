{ config, lib, pkgs, ... }:

let cfg = config.nix-home.cli-tools;
in {
  options.nix-home.cli-tools = {
    enable = lib.mkEnableOption "CLI tool configurations (bat, fzf, ripgrep, direnv)";
    direnv = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable direnv + nix-direnv (disable for servers and non-dev agents)";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.direnv = lib.mkIf cfg.direnv {
      enable = true;
      package = pkgs.unstable.direnv;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

    programs.bat = {
      enable = true;
      config = {
        theme = "TwoDark";
        pager = "less -FR";
      };
    };

    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
      defaultCommand = "fd --type f --hidden --follow --exclude .git";
      fileWidgetCommand = "fd --type f --hidden --follow --exclude .git";
      changeDirWidgetCommand = "fd --type d --hidden --follow --exclude .git";
      defaultOptions = [
        "--height 40%"
        "--layout=reverse"
        "--border"
      ];
    };

    programs.ripgrep = {
      enable = true;
      arguments = [
        "--smart-case"
        "--hidden"
        "--glob=!.git/*"
      ];
    };
  };
}
