{ config, lib, pkgs, ... }:

# Clipboard image → remote, for pasting screenshots into tools (e.g. Claude Code)
# running over ssh. The terminal escape channel (OSC 52) is text-only, so images
# must travel over ssh and be referenced by PATH. Two flows, both ending in a path:
#   imgpush <host>  — Mac pushes clipboard PNG to a remote, copies the path back.
#   clipimg         — on a remote reached via `sshclip`, pulls the Mac clipboard.
# Terminal-agnostic (works in iTerm and Ghostty); relies only on ssh + clipboard tools.

let
  user = config.home.username;
  sock = "/tmp/clip-${user}.sock";
  cacheSub = "img-paste";

  # Remote receiver for the push flow: stdin (PNG) → timestamped file → print path.
  pasteimg = pkgs.writeShellScriptBin "pasteimg" ''
    set -eu
    dir="''${XDG_CACHE_HOME:-$HOME/.cache}/${cacheSub}"
    mkdir -p "$dir"
    f="$dir/$(date +%Y%m%d-%H%M%S)-$$.png"
    cat > "$f"
    if [ ! -s "$f" ]; then rm -f "$f"; echo "pasteimg: empty (no image piped in)" >&2; exit 1; fi
    printf '%s\n' "$f"
  '';

  # iOS / Secure ShellFish flow: no clipboard-image command exists there, but the
  # remote mounts as a Location in the iOS Files app, so you save a screenshot from
  # Photos → Files → ~/inbox, then `lastimg` prints its path to drop into Claude Code.
  # Also covers anything dropped into ~/inbox by any means. Works on every platform.
  lastimg = pkgs.writeShellScriptBin "lastimg" ''
    set -eu
    dirs="$HOME/inbox ''${XDG_CACHE_HOME:-$HOME/.cache}/${cacheSub}"
    # shellcheck disable=SC2086
    f="$(ls -t $dirs/*.png $dirs/*.jpg $dirs/*.jpeg $dirs/*.PNG $dirs/*.HEIC 2>/dev/null | head -1)"
    if [ -z "$f" ]; then echo "lastimg: no images in: $dirs" >&2; exit 1; fi
    printf '%s\n' "$f"
  '';

  # Pull flow client: read the Mac clipboard image through the forwarded socket.
  clipimg = pkgs.writeShellScriptBin "clipimg" ''
    set -eu
    if [ ! -S "${sock}" ]; then
      echo "clipimg: no clipboard socket at ${sock} — reconnect with: sshclip <host>" >&2
      exit 1
    fi
    dir="''${XDG_CACHE_HOME:-$HOME/.cache}/${cacheSub}"
    mkdir -p "$dir"
    f="$dir/$(date +%Y%m%d-%H%M%S)-$$.png"
    ${pkgs.socat}/bin/socat -u UNIX-CONNECT:"${sock}" OPEN:"$f",creat,trunc 2>/dev/null || true
    if [ ! -s "$f" ]; then rm -f "$f"; echo "clipimg: empty (no image in Mac clipboard?)" >&2; exit 1; fi
    printf '%s\n' "$f"
  '';

  # Mac → remote push. Reference pasteimg via the nix profile so the non-interactive
  # ssh shell finds it regardless of remote PATH.
  imgpush = pkgs.writeShellScriptBin "imgpush" ''
    set -eu
    host="''${1:-}"
    if [ -z "$host" ]; then echo "usage: imgpush <host>" >&2; exit 1; fi
    path="$(${pkgs.pngpaste}/bin/pngpaste - | ssh "$host" 'PATH="$HOME/.nix-profile/bin:$PATH" pasteimg')" || {
      echo "imgpush: failed (no image in clipboard, or ssh/pasteimg error)" >&2; exit 1; }
    printf '%s' "$path" | pbcopy
    echo "pushed → $host:$path"
    echo "(remote path copied to clipboard — Cmd+V it into the ssh pane)"
  '';

  # ssh wrapper that forwards the Mac clipboard socket so `clipimg` works remotely.
  # Pre-cleans a stale remote socket so re-connects don't fail the forward.
  sshclip = pkgs.writeShellScriptBin "sshclip" ''
    set -eu
    host="''${1:-}"
    if [ -z "$host" ]; then echo "usage: sshclip <host> [ssh args...]" >&2; exit 1; fi
    shift
    ssh "$host" 'rm -f ${sock}' 2>/dev/null || true
    exec ssh -o ExitOnForwardFailure=yes -R "${sock}:${sock}" "$host" "$@"
  '';
in {
  config = {
    # Receivers everywhere (remotes need them); socat for the pull flow.
    home.packages = [ pasteimg clipimg lastimg pkgs.socat ]
      ++ lib.optionals pkgs.stdenv.isDarwin [ imgpush sshclip pkgs.pngpaste ];

    # Drop folder for the iOS Files-app flow (navigable name, ensured to exist).
    home.file."inbox/.keep".text = "";

    # Mac: serve the clipboard image on a private unix socket; sshclip forwards it.
    launchd.agents.clip-image-server = lib.mkIf pkgs.stdenv.isDarwin {
      enable = true;
      config = {
        ProgramArguments = [
          "${pkgs.socat}/bin/socat"
          "UNIX-LISTEN:${sock},fork,mode=0600"
          "EXEC:${pkgs.pngpaste}/bin/pngpaste -"
        ];
        RunAtLoad = true;
        KeepAlive = true;
        StandardErrorPath = "/tmp/clip-image-server.err";
      };
    };

    # Host completion for the helpers, like ssh.
    programs.zsh.initContent = lib.mkIf pkgs.stdenv.isDarwin
      (lib.mkAfter "compdef _ssh imgpush sshclip 2>/dev/null || true");
  };
}
