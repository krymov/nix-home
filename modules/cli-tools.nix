{ config, lib, pkgs, ... }:

let cfg = config.nix-home.cli-tools;
in {
  options.nix-home.cli-tools = {
    enable = lib.mkEnableOption "CLI tool configurations (bat, fzf, ripgrep, direnv, atuin, zoxide)";
    direnv = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable direnv + nix-direnv (disable for servers and non-dev agents)";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.direnv = lib.mkIf cfg.direnv {
      enable = true;
      package = (pkgs.unstable or {}).direnv or pkgs.direnv;
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
        "--height 80%"
        "--layout=reverse"
        "--border"
        "--info=inline-right"
        "--marker='▏'"
        "--pointer='▌'"
        # Catppuccin Mocha
        "--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8"
        "--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc"
        "--color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"
        "--color=selected-bg:#45475a"
      ];
      fileWidgetOptions = [
        "--preview 'bat -n --color=always --line-range :500 {} 2>/dev/null || cat {}'"
        "--bind 'ctrl-/:toggle-preview'"
      ];
      changeDirWidgetOptions = [
        "--preview 'eza --tree --level=2 --color=always {} 2>/dev/null || ls -la {}'"
      ];
      historyWidgetOptions = [
        "--preview 'echo {2..}'"
        "--preview-window up:3:hidden:wrap"
        "--bind 'ctrl-/:toggle-preview'"
        "--bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'"
        "--header 'CTRL-Y: copy  CTRL-/: preview'"
      ];
    };

    programs.atuin = {
      enable = true;
      enableZshIntegration = true;
      flags = [ "--disable-up-arrow" ];
      settings = {
        search_mode = "fuzzy";
        filter_mode = "global";
        filter_mode_shell_up_key_binding = "session";
        style = "compact";
        inline_height = 30;
        show_preview = true;
        show_help = false;
        enter_accept = true;
        workspaces = true;
        update_check = false;
        history_filter = [
          "^ls" "^ll" "^la" "^pwd$" "^exit$" "^clear$"
          "^cd$" "^cd \\.\\." "^cd -$" "^q$" "^wq$"
        ];
      };
    };

    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
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
