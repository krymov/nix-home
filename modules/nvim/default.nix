{ config, lib, pkgs, options, ... }:

let
  cfg = config.nix-home.nvim;
  configDir = ./.;
  hasSideload = options.programs.neovim ? sideloadInitLua;
in {
  options.nix-home.nvim = {
    enable = lib.mkEnableOption "neovim configuration";
    minimal = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Minimal config: basic editing, no LSP/mason/treesitter. For servers.";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      programs.neovim = {
        enable = true;
        withRuby = false;
        withPython3 = false;
        viAlias = true;
        vimAlias = true;
        vimdiffAlias = true;
        extraPackages = lib.optionals (!cfg.minimal) [
          pkgs.gcc
          pkgs.tree-sitter
          pkgs.gnumake
          pkgs.ripgrep
          pkgs.fd
          pkgs.lua-language-server
          pkgs.pyright
          pkgs.typescript-language-server
          pkgs.gopls
          pkgs.rust-analyzer
          pkgs.nil
          pkgs.vscode-langservers-extracted
          pkgs.yaml-language-server
          pkgs.bash-language-server
          pkgs.marksman
          pkgs.markdownlint-cli2
        ];
      };

      home.file = if cfg.minimal then {
        ".config/nvim/lua/options.lua".source = "${configDir}/lua/options.lua";
        ".config/nvim/lua/plugins/ui.lua".source = "${configDir}/lua/plugins/ui.lua";
      } else {
        ".config/nvim/lua" = {
          source = "${configDir}/lua";
          recursive = true;
        };
      };
    }

    # When sideloadInitLua is available, use it; otherwise manage init.lua manually
    (lib.mkIf hasSideload {
      programs.neovim.sideloadInitLua = true;
    })
    (lib.mkIf (!hasSideload) {
      home.file.".config/nvim/init.lua".source = "${configDir}/init.lua";
    })
  ]);
}
