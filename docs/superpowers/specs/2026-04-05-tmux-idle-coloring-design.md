# tmux-idle: Window Idle Coloring & Stale Detection

## Purpose

Add visual idle-time coloring to tmux window tabs so you can glance at the status bar and know which windows are fresh, stale, or need attention. Bell flag indicates "needs input" (e.g., Claude Code waiting).

Adapted from devrc's idle-fade system, ported to nix-home's module architecture with catppuccin palette support.

## Architecture

### New file: `modules/tmux-idle.nix`

Home-manager module with:
- `nix-home.tmux-idle.enable` — mkEnableOption
- Assertion: `nix-home.tmux.enable` must be true
- Installs 3 scripts to `~/.config/tmux/` via `home.file`
- Appends tmux hooks and status config via `programs.tmux.extraConfig`

### Scripts

All scripts installed to `~/.config/tmux/` via `home.file`. Color hex values injected as environment variables from Nix config — no hardcoded palette in shell.

#### `tmux-idle-update.sh` (~60 lines)

Batch color updater, called once per status-interval from `status-right` via `#(...)`.

Behavior:
1. Read current session, active window ID
2. Iterate all non-current windows via `tmux list-windows`
3. For each: read timestamp from `~/.tmux/activity/<window_id>`, compute idle seconds
4. Map idle seconds to color tier via env vars `IDLE_COLOR_0` through `IDLE_COLOR_7`
5. If bell flag set: add bold to style
6. Set `window-status-format` on the window via `tmux set-window-option`
7. Throttled orphan file cleanup (every 60s): remove activity files for windows that no longer exist

Thresholds (hardcoded, not configurable):
- Tier 0: <10 min (fresh)
- Tier 1: 10-30 min (active)
- Tier 2: 30-60 min (warm)
- Tier 3: 1-2 hr (cooling)
- Tier 4: 2-4 hr (idle)
- Tier 5: 4-8 hr (stale)
- Tier 6: 8-24 hr (dormant)
- Tier 7: >24 hr (ancient)

#### `tmux-activity-receiver.sh` (~15 lines)

Receives piped pane output, writes epoch timestamp to `~/.tmux/activity/<window_id>`. Argument: window ID. Throttled to 1 write/second via integer comparison.

#### `tmux-pipe-activity.sh` (~55 lines)

Manages pipe-pane lifecycle. Actions:
- `start <win_id>`: start piping pane output to activity-receiver
- `stop <win_id>`: stop piping
- `switch`: hot path on window focus change — stop pipe on now-focused window, start pipe on previously-focused window. Tracks previous via `~/.tmux/activity/.prev_<session>`
- `linked`: cold path on window creation — ensure all background windows have pipes
- `init`: cold path on session creation — same as linked

### Color palette

Colors are defined in Nix per catppuccin flavor and passed to `tmux-idle-update.sh` as env vars in the `#()` call within `status-right`.

#### Mocha (dark)

| Tier | Label | Color | Hex |
|------|-------|-------|-----|
| 0 | fresh | green | `#a6e3a1` |
| 1 | active | teal | `#94e2d5` |
| 2 | warm | blue | `#89b4fa` |
| 3 | cooling | yellow | `#f9e2af` |
| 4 | idle | peach | `#fab387` |
| 5 | stale | red | `#f38ba8` |
| 6 | dormant | mauve | `#cba6f7` |
| 7 | ancient | surface2 | `#585b70` |

#### Macchiato

| Tier | Label | Color | Hex |
|------|-------|-------|-----|
| 0 | fresh | green | `#a6da95` |
| 1 | active | teal | `#8bd5ca` |
| 2 | warm | blue | `#8aadf4` |
| 3 | cooling | yellow | `#eed49f` |
| 4 | idle | peach | `#f5a97f` |
| 5 | stale | red | `#ed8796` |
| 6 | dormant | mauve | `#c6a0f6` |
| 7 | ancient | surface2 | `#5b6078` |

#### Frappe

| Tier | Label | Color | Hex |
|------|-------|-------|-----|
| 0 | fresh | green | `#a6d189` |
| 1 | active | teal | `#81c8be` |
| 2 | warm | blue | `#8caaee` |
| 3 | cooling | yellow | `#e5c890` |
| 4 | idle | peach | `#ef9f76` |
| 5 | stale | red | `#e78284` |
| 6 | dormant | mauve | `#ca9ee6` |
| 7 | ancient | surface2 | `#626880` |

#### Latte (light)

| Tier | Label | Color | Hex |
|------|-------|-------|-----|
| 0 | fresh | green | `#40a02b` |
| 1 | active | teal | `#179299` |
| 2 | warm | blue | `#1e66f5` |
| 3 | cooling | yellow | `#df8e1d` |
| 4 | idle | peach | `#fe640b` |
| 5 | stale | red | `#d20f39` |
| 6 | dormant | mauve | `#8839ef` |
| 7 | ancient | surface2 | `#acb0be` |

### tmux config injected by the module

```tmux
# Idle coloring — disable default activity monitoring
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

# Window format — idle-update.sh overrides per-window, this is the default for new windows
set -g window-status-format '#[fg=<surface2>] #I:#W#F '
set -g window-status-current-format '#[fg=<text>,bg=<surface1>,bold] #I:#W #[default]'

# Faster refresh for responsive color transitions
set -g status-interval 2

# Batch idle updater (runs once per status-interval, outputs nothing)
# Colors passed as env vars so scripts have no hardcoded palette
set -g status-right '#(IDLE_COLOR_0=... IDLE_COLOR_7=... ~/.config/tmux/idle-update.sh) <existing status-right>'
```

### Interaction with existing tmux.nix

- `tmux.nix` currently sets `monitor-activity on` and `status-interval 5`
- When tmux-idle is enabled, its `extraConfig` runs after tmux.nix's, overriding both values
- The catppuccin plugin's window styling is overridden by `set-window-option window-status-format` calls from idle-update.sh (per-window options take precedence over global)
- The existing `status-right` (date_time, host, session via catppuccin) is preserved — idle-update call is prepended

### Changes to existing files

1. `default.nix` — add `./modules/tmux-idle.nix` to imports
2. `modules/profiles/personal.nix` — add `nix-home.tmux-idle = lib.mkDefault { enable = true; };`
3. `modules/profiles/workspace.nix` — same
4. `modules/profiles/dev-agent.nix` — same
5. `modules/profiles/agent.nix` — same
6. `modules/profiles/server.nix` — same

### State directory

`~/.tmux/activity/` — created by scripts at runtime. Contains:
- `<window_id>` files with epoch timestamps
- `.prev_<session>` files tracking previous window for switch optimization
- `.last_cleanup` file for throttling orphan cleanup

Not managed by Nix (runtime state).

## Testing

Manual verification after `home-manager switch`:
1. Open 3+ tmux windows
2. Work in one, leave others idle
3. After 10+ minutes, verify idle windows change color
4. Trigger a bell in a background window (`echo -e '\a'`), verify bold styling
5. Close a window, verify orphan cleanup removes its activity file within 60s
