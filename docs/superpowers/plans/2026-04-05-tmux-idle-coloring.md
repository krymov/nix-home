# tmux-idle: Window Idle Coloring Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add idle-time color coding to tmux window tabs with bell-based stale detection, integrated as a nix-home module with catppuccin palette support.

**Architecture:** Three shell scripts (activity receiver, pipe manager, batch color updater) installed via `home.file`, wired into tmux via hooks. A new `modules/tmux-idle.nix` module owns all config and exposes `nix-home.tmux-idle.enable`. Colors are defined in Nix per catppuccin flavor and passed to scripts as env vars.

**Tech Stack:** Nix (home-manager module), bash (scripts), tmux (hooks, pipe-pane, set-window-option)

**Spec:** `docs/superpowers/specs/2026-04-05-tmux-idle-coloring-design.md`

---

## File Structure

| File | Action | Responsibility |
|------|--------|----------------|
| `modules/tmux-idle.nix` | Create | Module: options, assertions, palette definitions, script installation, tmux extraConfig |
| `scripts/tmux-activity-receiver.sh` | Create | Receives piped output, writes activity timestamps |
| `scripts/tmux-pipe-activity.sh` | Create | Manages pipe-pane lifecycle (start/stop/switch/linked/init) |
| `scripts/tmux-idle-update.sh` | Create | Batch color updater, called per status-interval |
| `default.nix` | Modify | Add `./modules/tmux-idle.nix` import |
| `modules/profiles/personal.nix` | Modify | Enable tmux-idle |
| `modules/profiles/workspace.nix` | Modify | Enable tmux-idle |
| `modules/profiles/agent.nix` | Modify | Enable tmux-idle |
| `modules/profiles/dev-agent.nix` | Modify | Enable tmux-idle |
| `modules/profiles/server.nix` | Modify | Enable tmux-idle |

---

### Task 1: Create activity receiver script

**Files:**
- Create: `scripts/tmux-activity-receiver.sh`

- [ ] **Step 1: Write the script**

```bash
#!/usr/bin/env bash
# Receives piped pane output and updates activity timestamp.
# Called by pipe-pane with window_id as argument.
# Throttled to 1 write/second.

WINDOW_ID="$1"
ACTIVITY_DIR="${HOME}/.tmux/activity"
ACTIVITY_FILE="${ACTIVITY_DIR}/${WINDOW_ID//[@%]/}"

mkdir -p "$ACTIVITY_DIR"

last_update=0
while IFS= read -r _line; do
    now=$(date +%s)
    if (( now > last_update )); then
        echo "$now" > "$ACTIVITY_FILE"
        last_update=$now
    fi
done
```

- [ ] **Step 2: Make executable and commit**

```bash
chmod +x scripts/tmux-activity-receiver.sh
git add scripts/tmux-activity-receiver.sh
git commit -m "feat: add tmux activity receiver script"
```

---

### Task 2: Create pipe-pane manager script

**Files:**
- Create: `scripts/tmux-pipe-activity.sh`

- [ ] **Step 1: Write the script**

```bash
#!/usr/bin/env bash
# Manage pipe-pane for background activity tracking.
# Usage: tmux-pipe-activity.sh [start|stop|switch|linked|init] [window_id]

ACTIVITY_DIR="${HOME}/.tmux/activity"
mkdir -p "$ACTIVITY_DIR"

ACTION="$1"
WINDOW_ID="$2"

start_pipe() {
    local win_id="$1"
    local pane_id
    pane_id=$(tmux list-panes -t "$win_id" -F '#{pane_id}' 2>/dev/null | head -1)
    if [[ -n "$pane_id" ]]; then
        tmux pipe-pane -t "$pane_id" "~/.config/tmux/activity-receiver.sh '$win_id'"
    fi
}

stop_pipe() {
    local win_id="$1"
    local pane_id
    pane_id=$(tmux list-panes -t "$win_id" -F '#{pane_id}' 2>/dev/null | head -1)
    if [[ -n "$pane_id" ]]; then
        tmux pipe-pane -t "$pane_id"
    fi
}

case "$ACTION" in
    start)
        [[ -n "$WINDOW_ID" ]] && start_pipe "$WINDOW_ID"
        ;;
    stop)
        [[ -n "$WINDOW_ID" ]] && stop_pipe "$WINDOW_ID"
        ;;
    switch)
        SESSION=$(tmux display-message -p '#{session_name}')
        current_win=$(tmux display-message -p '#{window_id}')
        prev_file="${ACTIVITY_DIR}/.prev_${SESSION}"

        # Stop pipe on current window (now focused, don't need to track)
        stop_pipe "$current_win"

        # Start pipe on previous window (just moved to background)
        if [[ -f "$prev_file" ]]; then
            prev_win=$(< "$prev_file")
            [[ "$prev_win" != "$current_win" ]] && start_pipe "$prev_win"
        fi

        # Track current for next switch
        echo "$current_win" > "$prev_file"
        ;;
    linked|init)
        # Ensure all background windows have pipes
        tmux list-windows -F '#{window_id} #{window_active}' | while read -r win_id is_active; do
            if [[ "$is_active" == "0" ]]; then
                start_pipe "$win_id"
            fi
        done
        ;;
    *)
        echo "Usage: $0 [start|stop|switch|linked|init] [window_id]" >&2
        exit 1
        ;;
esac
```

- [ ] **Step 2: Make executable and commit**

```bash
chmod +x scripts/tmux-pipe-activity.sh
git add scripts/tmux-pipe-activity.sh
git commit -m "feat: add tmux pipe-pane activity manager script"
```

---

### Task 3: Create idle color updater script

**Files:**
- Create: `scripts/tmux-idle-update.sh`

The script reads color values from env vars `IDLE_COLOR_0` through `IDLE_COLOR_7`, set by the Nix module when calling it from `status-right`.

- [ ] **Step 1: Write the script**

```bash
#!/usr/bin/env bash
# Batch update all window tab colors based on idle time.
# Called once per status-interval from status-right.
# Colors passed via IDLE_COLOR_0..7 env vars from Nix config.

ACTIVITY_DIR="${HOME}/.tmux/activity"
mkdir -p "$ACTIVITY_DIR"

NOW=$(date +%s)
SESSION=$(tmux display-message -p '#{session_name}')
ACTIVE_WIN=$(tmux display-message -p '#{window_id}')

while IFS='|' read -r win_id win_idx win_name win_flags bell_flag; do
    [[ "$win_id" == "$ACTIVE_WIN" ]] && continue

    # Read activity timestamp
    activity_file="${ACTIVITY_DIR}/${win_id//[@%]/}"
    if [[ -f "$activity_file" ]]; then
        last_activity=$(< "$activity_file")
        idle_secs=$((NOW - last_activity))
    else
        idle_secs=99999
    fi

    # Map idle time to color tier
    if (( idle_secs < 600 )); then
        color="$IDLE_COLOR_0"
    elif (( idle_secs < 1800 )); then
        color="$IDLE_COLOR_1"
    elif (( idle_secs < 3600 )); then
        color="$IDLE_COLOR_2"
    elif (( idle_secs < 7200 )); then
        color="$IDLE_COLOR_3"
    elif (( idle_secs < 14400 )); then
        color="$IDLE_COLOR_4"
    elif (( idle_secs < 28800 )); then
        color="$IDLE_COLOR_5"
    elif (( idle_secs < 86400 )); then
        color="$IDLE_COLOR_6"
    else
        color="$IDLE_COLOR_7"
    fi

    # Bell override: bold
    if [[ "$bell_flag" == "1" ]]; then
        style="fg=$color,bg=default,bold"
    else
        style="fg=$color,bg=default"
    fi

    # Strip activity '#' flag from display
    win_flags="${win_flags//#/}"

    tmux set-window-option -t "$win_id" window-status-format \
        "#[$style] ${win_idx}:${win_name}${win_flags} " 2>/dev/null
done < <(tmux list-windows -t "$SESSION" -F '#{window_id}|#{window_index}|#{window_name}|#{window_flags}|#{window_bell_flag}')

# Throttled orphan cleanup (every 60s)
cleanup_marker="${ACTIVITY_DIR}/.last_cleanup"
do_cleanup=0
if [[ -f "$cleanup_marker" ]]; then
    last_cleanup=$(< "$cleanup_marker")
    (( NOW - last_cleanup > 60 )) && do_cleanup=1
else
    do_cleanup=1
fi

if (( do_cleanup )); then
    echo "$NOW" > "$cleanup_marker"
    declare -A valid
    while read -r wid; do
        valid["${wid//[@%]/}"]=1
    done < <(tmux list-windows -a -F '#{window_id}')

    for f in "$ACTIVITY_DIR"/*; do
        [[ -f "$f" ]] || continue
        fname=$(basename "$f")
        [[ "$fname" == .* ]] && continue
        if [[ -z "${valid[$fname]+x}" ]]; then
            rm -f "$f"
        fi
    done
fi
```

- [ ] **Step 2: Make executable and commit**

```bash
chmod +x scripts/tmux-idle-update.sh
git add scripts/tmux-idle-update.sh
git commit -m "feat: add tmux idle color updater script"
```

---

### Task 4: Create `modules/tmux-idle.nix` module

**Files:**
- Create: `modules/tmux-idle.nix`

This is the core module. It defines the catppuccin palette per flavor, installs scripts via `home.file`, and injects tmux hooks + status config.

- [ ] **Step 1: Write the module**

```nix
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
```

- [ ] **Step 2: Verify Nix syntax**

```bash
cd /Users/mark/workspace/personal/repos/nix-home
nix-instantiate --parse modules/tmux-idle.nix
```

Expected: parsed output with no errors (or a clean expression). If syntax error, fix and re-run.

- [ ] **Step 3: Commit**

```bash
git add modules/tmux-idle.nix
git commit -m "feat: add tmux-idle module with catppuccin palette support"
```

---

### Task 5: Wire module into default.nix and profiles

**Files:**
- Modify: `default.nix:1-16`
- Modify: `modules/profiles/personal.nix:17`
- Modify: `modules/profiles/workspace.nix:19`
- Modify: `modules/profiles/agent.nix:20`
- Modify: `modules/profiles/dev-agent.nix:20`
- Modify: `modules/profiles/server.nix:19`

- [ ] **Step 1: Add import to default.nix**

Add `./modules/tmux-idle.nix` after `./modules/tmux.nix` in the imports list:

```nix
    ./modules/tmux.nix
    ./modules/tmux-idle.nix
```

- [ ] **Step 2: Enable in all profiles**

Add this line to each profile's config block, after the `nix-home.tmux` line:

```nix
    nix-home.tmux-idle = lib.mkDefault { enable = true; };
```

Files to modify:
- `modules/profiles/personal.nix` — after line 19
- `modules/profiles/workspace.nix` — after line 19
- `modules/profiles/agent.nix` — after line 20
- `modules/profiles/dev-agent.nix` — after line 20
- `modules/profiles/server.nix` — after line 19

- [ ] **Step 3: Commit**

```bash
git add default.nix modules/profiles/
git commit -m "feat: enable tmux-idle in all profiles"
```

---

### Task 6: Build and verify

- [ ] **Step 1: Run home-manager build**

```bash
cd /Users/mark/workspace/personal/repos/nix-home
nix build .#homeConfigurations.personal.activationPackage --no-link --print-out-paths
```

Expected: successful build, no errors.

- [ ] **Step 2: Inspect generated tmux config**

Check the built tmux.conf contains the idle coloring config:

```bash
result=$(nix build .#homeConfigurations.personal.activationPackage --no-link --print-out-paths)
grep -A5 "idle-update" "$result/home-files/.config/tmux/tmux.conf" || grep -rA5 "idle-update" "$result/"
```

Expected: the status-right line with `IDLE_COLOR_0` env vars and `idle-update.sh` call.

- [ ] **Step 3: Verify scripts are installed**

```bash
ls -la "$result/home-files/.config/tmux/"
```

Expected: `activity-receiver.sh`, `pipe-activity.sh`, `idle-update.sh` all present and executable.

- [ ] **Step 4: Commit any fixes if needed, then final commit**

```bash
git add -A
git status
# Only commit if there are changes
git diff --cached --quiet || git commit -m "fix: address build issues from tmux-idle integration"
```
