{ config, lib, pkgs, ... }:

let
  cfg = config.nix-home.tmux;
  env = config.nix-home.environment;

  # Coarse, deploy-level env chip for status-left. Per-pane truth lives in the
  # prompt (a pane SSH'd to prod from a dev box is flagged there, not here).
  envChip = {
    prod = "#[fg=#{@thm_crust},bg=#{@thm_red},bold] PROD #[default] ";
    staging = "#[fg=#{@thm_crust},bg=#{@thm_yellow},bold] STG #[default] ";
    dev = "";
  }.${env};

  # Active-pane border tint by blast-radius.
  activeBorderColor = {
    prod = "#{@thm_red}";
    staging = "#{@thm_yellow}";
    dev = "#{@thm_green}";
  }.${env};
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

    # Status-bar chip helpers (cross-platform; hide themselves when N/A).
    home.file.".config/tmux/mem.sh" = { source = ../scripts/tmux-mem.sh; executable = true; };
    home.file.".config/tmux/timew.sh" = { source = ../scripts/tmux-timew.sh; executable = true; };
    home.file.".config/tmux/battery.sh" = { source = ../scripts/tmux-battery.sh; executable = true; };

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
            set -g @resurrect-dir '$HOME/.local/share/tmux/resurrect'
            set -g @resurrect-processes 'nvim vim less man tail top htop btop'
          '';
        }
        {
          plugin = continuum;
          extraConfig = ''
            set -g @continuum-save-interval '5'
            set -g @continuum-restore 'on'
            set -g @continuum-boot 'on'
            set -g @continuum-boot-options 'iterm'
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

        # Pane borders — per-pane host reinforcement for the multiplex case.
        # #T (pane_title) carries user@host:dir, set by the shell precmd, so the
        # border reflects the REMOTE host after an ssh. Active border tints by env.
        set -g pane-border-status top
        set -g pane-border-format " #P #{pane_current_command} #[fg=#{@thm_overlay0}]#T "
        set -g pane-active-border-style "fg=${activeBorderColor}"

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
        # status-left = project/session identity (the durable navigational unit),
        # plus a coarse deploy-level env chip. Not overridden by tmux-idle.
        set -g @host_env "${env}"
        set -g status-left "${envChip}#[fg=#{@thm_crust},bg=#{@thm_mauve},bold] #S #[default] "
        set -g status-right-length 200
        set -g status-left-length 100

        # Right-side chips — SINGLE source of truth. tmux-idle now only *appends*
        # its invisible idle-color updater instead of overwriting this.
        # continuum save trigger must be in status-right or auto-save won't fire.
        set -g  status-right "#(${pkgs.tmuxPlugins.continuum}/share/tmux-plugins/continuum/scripts/continuum_save.sh)"
        # Prefix indicator — lit only while the prefix key is active (commas in #[] escaped as #,).
        set -ag status-right "#{?client_prefix,#[fg=#{@thm_crust}#,bg=#{@thm_red}#,bold] PREFIX #[default] ,}"
        # Timewarrior — active task + elapsed (auto-tracked per session); hidden when idle.
        set -ag status-right "#(THM_FG='#{@thm_crust}' THM_BG='#{@thm_peach}' ~/.config/tmux/timew.sh)"
        # Battery — real detection; hidden on desktops/VMs/containers/servers.
        set -ag status-right "#(THM_FG='#{@thm_crust}' THM_BG='#{@thm_green}' ~/.config/tmux/battery.sh)"
        # CPU (catppuccin) + RAM (script).
        set -agF status-right "#{E:@catppuccin_status_cpu}"
        set -ag  status-right "#[fg=#{@thm_crust},bg=#{@thm_sky},bold]  #(~/.config/tmux/mem.sh) #[default] "
        # NOTE: kube-context now lives in the starship prompt (per-pane, travels over ssh).
        set -ag  status-right "#{E:@catppuccin_status_date_time}"
        set -ag  status-right "#{E:@catppuccin_status_host}"
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
