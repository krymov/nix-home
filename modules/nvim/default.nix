{ config, lib, pkgs, ... }:

let
  cfg = config.nix-home.nvim;
  configDir = ./.;
in {
  options.nix-home.nvim = {
    enable = lib.mkEnableOption "neovim configuration";
    minimal = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Minimal config: basic editing, no LSP/mason/treesitter. For servers.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
      extraPackages = lib.optionals (!cfg.minimal) [
        pkgs.gcc  # treesitter parser compilation
      ];
    };

    # Full config: symlink entire lua/ directory (LSP, plugins, etc.)
    # Minimal config: only symlink init.lua and options.lua + ui plugin (catppuccin)
    home.file = if cfg.minimal then {
      ".config/nvim/init.lua".source = "${configDir}/init.lua";
      ".config/nvim/lua/options.lua".source = "${configDir}/lua/options.lua";
      ".config/nvim/lua/plugins/ui.lua".source = "${configDir}/lua/plugins/ui.lua";
    } else {
      ".config/nvim/init.lua".source = "${configDir}/init.lua";
      ".config/nvim/lua" = {
        source = "${configDir}/lua";
        recursive = true;
      };
    };
  };
}
