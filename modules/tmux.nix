{ config, lib, pkgs, ... }:

let cfg = config.nix-home.tmux;
in {
  options.nix-home.tmux = {
    enable = lib.mkEnableOption "tmux configuration";
  };

  config = lib.mkIf cfg.enable {
    programs.tmux = {
      enable = true;
      terminal = "tmux-256color";
      mouse = true;
      keyMode = "vi";
      baseIndex = 1;
      escapeTime = 0;
      historyLimit = 100000;
      clock24 = true;

      plugins = with pkgs.tmuxPlugins; [
        sensible
        yank
        {
          plugin = resurrect;
          extraConfig = ''
            set -g @resurrect-capture-pane-contents 'on'
            set -g @resurrect-strategy-nvim 'session'
          '';
        }
        {
          plugin = continuum;
          extraConfig = ''
            set -g @continuum-save-interval '10'
            set -g @continuum-restore 'on'
          '';
        }
        {
          plugin = catppuccin;
          extraConfig = ''
            set -g @catppuccin_flavor "mocha"
            set -g @catppuccin_status_background "none"
            set -g @catppuccin_window_status_style "rounded"
            set -g @catppuccin_window_default_text " #W"
            set -g @catppuccin_window_current_text " #W"
            set -g @catppuccin_window_flags "icon"
            set -g @catppuccin_date_time_text " %H:%M"
          '';
        }
      ];

      extraConfig = ''
        # Force zsh as default shell
        set -g default-command "${pkgs.zsh}/bin/zsh"

        # Terminal overrides
        set -ag terminal-overrides ",xterm-256color:RGB"
        set -g set-clipboard on
        set -g detach-on-destroy off
        set -g focus-events on
        set -g status-interval 5
        set -g renumber-windows on

        # Activity monitoring
        setw -g monitor-activity on
        set -g visual-activity off

        # Window options
        setw -g pane-base-index 1
        setw -g xterm-keys on
        setw -g automatic-rename on
        setw -g allow-rename off
        set -g exit-unattached off

        # Split panes (inherit cwd)
        bind | split-window -h -c "#{pane_current_path}"
        bind - split-window -v -c "#{pane_current_path}"
        bind '"' split-window -v -c "#{pane_current_path}"
        bind % split-window -h -c "#{pane_current_path}"

        # New window inherits cwd
        bind c new-window -c "#{pane_current_path}"

        # Reload config
        bind r source-file ~/.config/tmux/tmux.conf \; display-message "tmux config reloaded!"

        # Pane navigation (vim-like)
        bind h select-pane -L
        bind j select-pane -D
        bind k select-pane -U
        bind l select-pane -R

        # Pane resizing (repeatable)
        bind -r H resize-pane -L 5
        bind -r J resize-pane -D 5
        bind -r K resize-pane -U 5
        bind -r L resize-pane -R 5

        # Window navigation
        bind -r C-h previous-window
        bind -r C-l next-window

        # Session navigation
        bind -r ( switch-client -p
        bind -r ) switch-client -n

        # Quick pane layouts
        bind M-1 select-layout even-horizontal
        bind M-2 select-layout even-vertical
        bind M-3 select-layout main-horizontal
        bind M-4 select-layout main-vertical
        bind M-5 select-layout tiled

        # Copy mode
        bind Enter copy-mode
        bind -T copy-mode-vi v send -X begin-selection
        bind -T copy-mode-vi y send -X copy-selection-and-cancel
        bind -T copy-mode-vi r send -X rectangle-toggle

        # Status bar
        set -g status-position top
        set -g status-left ""
        set -g status-right-length 80
        set -g status-right "#{E:@catppuccin_status_session} #{E:@catppuccin_status_date_time}"

        # Timewarrior integration — auto-track time per tmux session
        set-hook -g client-session-changed 'run-shell -b "command -v timew >/dev/null && timew start tmux:#{session_name} 2>/dev/null || true"'
        set-hook -g client-detached 'run-shell -b "command -v timew >/dev/null && timew stop 2>/dev/null || true"'
      '';
    };
  };
}
