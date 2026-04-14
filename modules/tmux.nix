{ config, lib, pkgs, ... }:

let cfg = config.nix-home.tmux;
in {
  options.nix-home.tmux = {
    enable = lib.mkEnableOption "tmux configuration";
    catppuccinFlavor = lib.mkOption {
      type = lib.types.enum [ "mocha" "macchiato" "frappe" "latte" ];
      default = "mocha";
      description = "Catppuccin flavor for tmux theme. Use different flavors per profile to visually distinguish environments.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.file.".gitmux.conf".text = ''
      tmux:
        symbols:
          branch: " "
          hashprefix: ":"
          ahead: "↑"
          behind: "↓"
          staged: "●"
          conflict: "✖"
          modified: "✚"
          untracked: "…"
          stashed: "⚑"
          clean: "✔"
        styles:
          clear: "#[fg=#{@thm_fg}]"
          state: "#[fg=#{@thm_red},bold]"
          branch: "#[fg=#{@thm_mauve},bold]"
          remote: "#[fg=#{@thm_teal}]"
          staged: "#[fg=#{@thm_green},bold]"
          modified: "#[fg=#{@thm_yellow},bold]"
          untracked: "#[fg=#{@thm_blue},bold]"
          clean: "#[fg=#{@thm_green},bold]"
          stashed: "#[fg=#{@thm_peach},bold]"
        layout: [branch, " ", divergence, " - ", flags]
    '';

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
        cpu
        battery
        {
          plugin = catppuccin;
          extraConfig = ''
            set -g @catppuccin_flavor "${cfg.catppuccinFlavor}"
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
        set -g status-right-length 200
        set -g status-left-length 100

        # Right side: gitmux | directory | kube | battery (graceful) | cpu | time | session
        set -g  status-right ""
        set -ag status-right "#(${pkgs.gitmux}/bin/gitmux -cfg $HOME/.gitmux.conf '#{pane_current_path}')"
        set -ag status-right "#{E:@catppuccin_status_directory}"
        # K8s context: only show if kubectl exists and a context is set
        set -ag status-right "#(ctx=$(kubectl config current-context 2>/dev/null) && printf ' ⎈ %s' \"$ctx\" || true)"
        # Battery: graceful fallback — only renders if battery plugin detects a battery
        set -agF status-right "#{E:@catppuccin_status_battery}"
        set -agF status-right "#{E:@catppuccin_status_cpu}"
        set -ag  status-right "#{E:@catppuccin_status_date_time}"
        set -ag  status-right "#{E:@catppuccin_status_session}"

        # Lazygit popup
        bind g display-popup -E -w 90% -h 90% -d "#{pane_current_path}" "${pkgs.lazygit}/bin/lazygit"

        # Sessionizer — Ctrl-F to fuzzy-find a project and open as tmux session
        bind C-f display-popup -E -w 80% -h 60% "\
          dir=$(${pkgs.fd}/bin/fd --type d --max-depth 1 . ~/workspace 2>/dev/null | ${pkgs.fzf}/bin/fzf --reverse --header 'Pick a project') && \
          name=$(basename \"$dir\" | tr . _) && \
          if ! tmux has-session -t=\"$name\" 2>/dev/null; then \
            tmux new-session -ds \"$name\" -c \"$dir\"; \
          fi && \
          tmux switch-client -t \"$name\""

        # Timewarrior integration — auto-track time per tmux session
        set-hook -g client-session-changed 'run-shell -b "command -v timew >/dev/null && timew start tmux:#{session_name} >/dev/null 2>&1 || true"'
        set-hook -g client-detached 'run-shell -b "command -v timew >/dev/null && timew stop >/dev/null 2>&1 || true"'
      '';
    };
  };
}
