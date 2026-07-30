{ config, lib, pkgs, ... }:

let
  cfg = config.nix-home.herdr;
  tmuxCfg = config.nix-home.tmux;

  # herdr ships exactly two catppuccin variants; everything darker than latte
  # maps to the same "catppuccin" base.
  themeName = if tmuxCfg.catppuccinFlavor == "latte" then "catppuccin-latte" else "catppuccin";
in {
  options.nix-home.herdr = {
    enable = lib.mkEnableOption "herdr agent multiplexer configuration";

    prefix = lib.mkOption {
      type = lib.types.str;
      default = "ctrl+a";
      description = ''
        herdr prefix key. Defaults to ctrl+a — NOT herdr's own ctrl+b default —
        because tmux keeps ctrl+b here, and a tmux session running inside a herdr
        pane would otherwise swallow every prefix chord.
      '';
    };

    worktreeDirectory = lib.mkOption {
      type = lib.types.str;
      default = "~/workspace/.worktrees";
      description = "Root for git worktrees herdr checks out (prefix+shift+g).";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.herdr ];

    home.file.".config/herdr/config.toml".text = ''
      # Managed by nix-home (modules/herdr.nix) — edits here are overwritten.
      # Full annotated defaults: herdr --default-config
      # Reload after a rebuild: herdr server reload-config

      onboarding = false

      [theme]
      name = "${themeName}"
      auto_switch = false

      [terminal]
      default_shell = "${pkgs.zsh}/bin/zsh"
      shell_mode = "auto"
      # New panes/tabs inherit the source pane's cwd, matching the tmux bindings.
      new_cwd = "follow"

      [update]
      # The binary is nix-managed; `herdr update` can't touch it, so don't nag.
      version_check = false
      # Agent-detection manifests are data, not the binary — keep them current.
      manifest_check = true

      [keys]
      prefix = "${cfg.prefix}"

      # Pane focus/splits mirror the tmux bindings in modules/tmux.nix.
      focus_pane_left = "prefix+h"
      focus_pane_down = "prefix+j"
      focus_pane_up = "prefix+k"
      focus_pane_right = "prefix+l"
      split_vertical = "prefix+v"
      split_horizontal = "prefix+minus"
      resize_mode = "prefix+r"
      zoom = "prefix+z"
      close_pane = "prefix+x"

      new_tab = "prefix+c"
      previous_tab = "prefix+p"
      next_tab = "prefix+n"
      switch_tab = "prefix+1..9"

      # Workspaces ≈ tmux sessions. Chords use ctrl+letter, not punctuation:
      # only minus/comma/ampersand/plus/backtick are reliably parsed.
      previous_workspace = "prefix+ctrl+p"
      next_workspace = "prefix+ctrl+n"
      switch_workspace = "prefix+shift+1..9"
      workspace_picker = "prefix+w"
      new_worktree = "prefix+shift+g"

      # Attention queue — jump between agents that changed state.
      previous_agent = "prefix+ctrl+k"
      next_agent = "prefix+ctrl+j"
      focus_agent = "prefix+alt+1..9"

      toggle_sidebar = "prefix+b"
      detach = "prefix+q"

      # lazygit popup — same muscle memory as tmux `prefix g`.
      [[keys.command]]
      key = "prefix+g"
      type = "popup"
      command = "${pkgs.lazygit}/bin/lazygit"
      width = "90%"
      height = "90%"

      [worktrees]
      directory = "${cfg.worktreeDirectory}"

      [ui]
      sidebar_width = 26
      agent_panel_sort = "priority"
      pane_borders = true
      show_agent_labels_on_pane_borders = true
      hide_tab_bar_when_single_tab = true
      prompt_new_tab_name = false

      [ui.toast]
      # In-app toasts: terminal/system delivery depends on the outer terminal
      # cooperating, which breaks the moment you attach over ssh.
      delivery = "herdr"

      [ui.sound]
      enabled = true

      [session]
      resume_agents_on_restore = true

      [remote]
      manage_ssh_config = true
    '';
  };
}
