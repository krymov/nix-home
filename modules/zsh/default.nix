{ config, lib, pkgs, ... }:

let
  cfg = config.nix-home.zsh;
  configDir = ./.;
in {
  options.nix-home.zsh = {
    enable = lib.mkEnableOption "zsh configuration";
    emacsBindings = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enhanced emacs keybindings (Alt word nav, iTerm2+tmux compat)";
    };
  };

  config = lib.mkIf cfg.enable {
    # Symlink modular zsh config files
    home.file = {
      ".zsh/env.zsh".source = "${configDir}/env.zsh";
      ".zsh/aliases.zsh".source = "${configDir}/aliases.zsh";
      ".zsh/functions.zsh".source = "${configDir}/functions.zsh";
      ".zsh/completions.zsh".source = "${configDir}/completions.zsh";
    };

    programs.zsh = {
      enable = true;
      dotDir = config.home.homeDirectory;
      enableCompletion = true;
      autocd = true;

      autosuggestion = {
        enable = true;
        highlight = "fg=8";
        strategy = [ "history" "completion" ];
      };

      syntaxHighlighting.enable = true;
      historySubstringSearch.enable = true;

      defaultKeymap = "emacs";

      history = {
        size = 50000;
        save = 50000;
        path = "$HOME/.zsh_history";
        ignoreAllDups = true;
        share = true;
        expireDuplicatesFirst = true;
      };

      completionInit = ''
        autoload -Uz compinit
        if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
          compinit
        else
          compinit -C
        fi
      '';

      initContent = lib.mkMerge [
        # Phase 1: very top — nix paths, platform detection, tmux auto-attach
        (lib.mkBefore ''
          # Nix paths for tmux server
          export PATH="$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH"

          # Workspace detection
          if [[ -d "/Volumes/wh/workspace" ]]; then
            WORKSPACE="/Volumes/wh/workspace"
          elif [[ -d "$HOME/workspace" ]]; then
            WORKSPACE="$HOME/workspace"
          else
            WORKSPACE="$HOME"
          fi

          # iTerm2: auto-attach to tmux
          if [[ -n "$ITERM_SESSION_ID" && -z "$TMUX" ]]; then
            tmux new-session -A -s main -c "$WORKSPACE"
          fi

          # Platform detection
          case "$OSTYPE" in
            darwin*)
              export IS_MAC=1
              export PLATFORM="macos"
              ;;
            linux*)
              export IS_LINUX=1
              if command -v nixos-rebuild >/dev/null 2>&1; then
                export PLATFORM="nixos"
              else
                export PLATFORM="linux"
              fi
              ;;
            *)
              export PLATFORM="unknown"
              ;;
          esac
        '')

        # Phase 2: before compinit — fpath setup
        (lib.mkOrder 550 ''
          # Tier 1: Nix-managed completions (automatic)
          fpath+=("$HOME/.nix-profile/share/zsh/site-functions")
          fpath+=("/run/current-system/sw/share/zsh/site-functions")

          # Tier 3: Manual installs (zsh-comp helper)
          fpath+=("''${XDG_DATA_HOME:-$HOME/.local/share}/zsh/completions")

          # Legacy custom completions dir
          fpath=(~/.zsh/completions $fpath)
        '')

        # Phase 3: after compinit
        ''
          # Terminal settings
          if [[ -n "$TMUX" ]]; then
            export TERM="tmux-256color"
          elif [[ "$TERM" != "xterm-kitty" ]]; then
            export TERM="xterm-256color"
          fi

          # Shell options
          setopt promptsubst
          setopt hist_verify
          setopt extended_glob nomatch notify
          setopt auto_pushd pushd_ignore_dups pushd_minus

          HISTORY_IGNORE='(ls|ll|la|pwd|exit|clear|history|cd|cd ..|cd -|q|wq|ZZ)'

          # PATH management
          typeset -U path
          path=(
            "$HOME/.dotfiles/bin"
            "$HOME/.local/bin"
            "$HOME/bin"
            "$HOME/.dotfiles"
            "$HOME/.opencode/bin"
            $path
          )
          export PATH

          # XDG Base Directory
          export XDG_CONFIG_HOME="$HOME/.config"
          export XDG_DATA_HOME="$HOME/.local/share"
          export XDG_CACHE_HOME="$HOME/.cache"
          export XDG_STATE_HOME="$HOME/.local/state"
          mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$XDG_STATE_HOME"

          # Tier 2: Cached runtime completions (auto-regenerate when binary updates)
          _cache_dir="''${XDG_CACHE_HOME:-$HOME/.cache}/zsh-completions"
          mkdir -p "$_cache_dir"
          for cmd in kubectl helm stern; do
            _cache="$_cache_dir/_$cmd"
            _bin="$(command -v $cmd 2>/dev/null)"
            if [[ -n "$_bin" ]] && [[ ! -f "$_cache" || "$_bin" -nt "$_cache" ]]; then
              $cmd completion zsh > "$_cache" 2>/dev/null
            fi
          done
          fpath+=("$_cache_dir")

          # Load modular config files
          for config_file in "$HOME/.zsh/"{env,aliases,functions,completions}.zsh; do
            [[ -r "$config_file" ]] && source "$config_file"
          done

          ${lib.optionalString cfg.emacsBindings ''
          # Emacs keybindings — word navigation for iTerm2+tmux
          bindkey $'\e[1;3D' backward-word
          bindkey $'\e[1;3C' forward-word
          bindkey $'\e\x7f' backward-kill-word
          bindkey $'\ed' kill-word
          bindkey $'\e[H' beginning-of-line
          bindkey $'\e[F' end-of-line
          bindkey '^_' undo
          bindkey $'\e/' redo
          ''}

          # Autosuggestion behavior
          ZSH_AUTOSUGGEST_ACCEPT_WIDGETS=()
          ZSH_AUTOSUGGEST_PARTIAL_ACCEPT_WIDGETS=()
          ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
          bindkey '^[[C' autosuggest-accept
          bindkey '^ ' autosuggest-accept
          bindkey '^F' autosuggest-accept
          bindkey '^[f' forward-word

          # History substring search keybindings
          if zle -la | grep -q "history-substring-search"; then
            bindkey '^[[A' history-substring-search-up
            bindkey '^[[B' history-substring-search-down
            bindkey '^P' history-substring-search-up
            bindkey '^N' history-substring-search-down
          fi

          # Local machine-specific config
          [[ -r "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

          autoload -U +X bashcompinit && bashcompinit
          export USE_GKE_GCLOUD_AUTH_PLUGIN=True

          # AI API Keys
          if [[ -f "$HOME/.config/ai-keys.env" ]]; then
            source "$HOME/.config/ai-keys.env"
          fi
        ''
      ];
    };

    home.sessionVariables = {
      EDITOR = "nvim";
      PAGER = "less";
      NIX_PATH = "$HOME/.nix-defexpr/channels\${NIX_PATH:+:}$NIX_PATH";
    } // lib.optionalAttrs pkgs.stdenv.isDarwin {
      HOMEBREW_NO_AUTO_UPDATE = "1";
    };
  };
}
