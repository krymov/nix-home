{ config, lib, pkgs, ... }:

let
  cfg = config.nix-home.tmux-idle;
  tmuxCfg = config.nix-home.tmux;

  # Catppuccin palettes: 8 idle tiers per flavor
  palettes = {
    mocha = {
      c0 = "#a6e3a1"; c1 = "#94e2d5"; c2 = "#89b4fa"; c3 = "#f9e2af";
      c4 = "#fab387"; c5 = "#f38ba8"; c6 = "#cba6f7"; c7 = "#585b70";
      text = "#cdd6f4"; surface1 = "#45475a"; surface2 = "#585b70";
    };
    macchiato = {
      c0 = "#a6da95"; c1 = "#8bd5ca"; c2 = "#8aadf4"; c3 = "#eed49f";
      c4 = "#f5a97f"; c5 = "#ed8796"; c6 = "#c6a0f6"; c7 = "#5b6078";
      text = "#cad3f5"; surface1 = "#494d64"; surface2 = "#5b6078";
    };
    frappe = {
      c0 = "#a6d189"; c1 = "#81c8be"; c2 = "#8caaee"; c3 = "#e5c890";
      c4 = "#ef9f76"; c5 = "#e78284"; c6 = "#ca9ee6"; c7 = "#626880";
      text = "#c6d0f5"; surface1 = "#51576d"; surface2 = "#626880";
    };
    latte = {
      c0 = "#40a02b"; c1 = "#179299"; c2 = "#1e66f5"; c3 = "#df8e1d";
      c4 = "#fe640b"; c5 = "#d20f39"; c6 = "#8839ef"; c7 = "#acb0be";
      text = "#4c4f69"; surface1 = "#bcc0cc"; surface2 = "#acb0be";
    };
  };

  p = palettes.${tmuxCfg.catppuccinFlavor};

  # Env var string for passing colors to idle-update.sh
  colorEnv = builtins.concatStringsSep " " [
    "IDLE_COLOR_0='${p.c0}'" "IDLE_COLOR_1='${p.c1}'"
    "IDLE_COLOR_2='${p.c2}'" "IDLE_COLOR_3='${p.c3}'"
    "IDLE_COLOR_4='${p.c4}'" "IDLE_COLOR_5='${p.c5}'"
    "IDLE_COLOR_6='${p.c6}'" "IDLE_COLOR_7='${p.c7}'"
  ];
in {
  options.nix-home.tmux-idle = {
    enable = lib.mkEnableOption "tmux window idle coloring and stale detection";
  };

  config = lib.mkIf cfg.enable {
    assertions = [{
      assertion = tmuxCfg.enable;
      message = "nix-home.tmux-idle requires nix-home.tmux to be enabled";
    }];

    # Install scripts to ~/.config/tmux/
    home.file.".config/tmux/activity-receiver.sh" = {
      source = ../scripts/tmux-activity-receiver.sh;
      executable = true;
    };
    home.file.".config/tmux/pipe-activity.sh" = {
      source = ../scripts/tmux-pipe-activity.sh;
      executable = true;
    };
    home.file.".config/tmux/idle-update.sh" = {
      source = ../scripts/tmux-idle-update.sh;
      executable = true;
    };

    programs.tmux.extraConfig = lib.mkAfter ''
      # Idle coloring — override default activity monitoring
      set -g monitor-activity off
      set -g visual-activity off

      # Bell — visual highlight only
      set -g monitor-bell on
      set -g visual-bell off
      set -g bell-action current

      # Pipe-pane activity tracking hooks
      set-hook -g after-select-window 'run-shell -b "~/.config/tmux/pipe-activity.sh switch"'
      set-hook -g window-linked 'run-shell -b "~/.config/tmux/pipe-activity.sh linked"'
      set-hook -g session-created 'run-shell -b "~/.config/tmux/pipe-activity.sh init"'

      # Window format — idle-update.sh overrides per-window, this is the default
      set -g window-status-format '#[fg=${p.surface2}] #I:#W#F '
      set -g window-status-current-format '#[fg=${p.text},bg=${p.surface1},bold] #I:#W #[default]'

      # Faster refresh for responsive color transitions
      set -g status-interval 2

      # Batch idle updater — colors injected as env vars
      set -g status-right "#(${colorEnv} ~/.config/tmux/idle-update.sh)#{E:@catppuccin_status_date_time} #{E:@catppuccin_status_host} #{E:@catppuccin_status_session}"
    '';
  };
}
