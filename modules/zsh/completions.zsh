# Completion styling — no tool-specific sourcing (handled by nix fpath + cached generators)

# Source Typer/Click completions (they register via compdef, need explicit sourcing)
for f in ~/.zsh/completions/_*(N); do
  [[ -f "$f" ]] && grep -q 'compdef.*_completion' "$f" && source "$f"
done

# Styling
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' rehash true
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache
zstyle ':completion:*' accept-exact '*(N)'
zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*:match:*' original only
zstyle ':completion:*:approximate:*' max-errors 1 numeric
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
zstyle ':completion:*:warnings' format '%F{red}-- no matches found --%f'
zstyle ':completion:*:functions' ignored-patterns '(_*|pre(cmd|exec))'

# Kill command completion
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"

[[ ! -d ~/.zsh/cache ]] && mkdir -p ~/.zsh/cache
setopt complete_aliases

# Alias completions
compdef k=kubectl 2>/dev/null

# Tmux session completion
if command -v tmux >/dev/null; then
  _tmux_sessions() {
    local sessions
    sessions=($(tmux list-sessions -F '#S' 2>/dev/null))
    _describe 'sessions' sessions
  }
  compdef _tmux_sessions ta
  compdef _tmux_sessions tk
fi

compdef '_path_files -/' mkcd 2>/dev/null
compdef '_files' extract 2>/dev/null
