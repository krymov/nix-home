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

# fzf-tab previews
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath 2>/dev/null || ls $realpath'
zstyle ':fzf-tab:complete:z:*' fzf-preview 'eza -1 --color=always $realpath 2>/dev/null || ls $realpath'
zstyle ':fzf-tab:complete:ls:*' fzf-preview 'eza -1 --color=always $realpath 2>/dev/null || ls $realpath'
zstyle ':fzf-tab:complete:eza:*' fzf-preview 'eza -1 --color=always $realpath 2>/dev/null'
zstyle ':fzf-tab:complete:cat:*' fzf-preview 'bat -n --color=always $realpath 2>/dev/null || cat $realpath'
zstyle ':fzf-tab:complete:bat:*' fzf-preview 'bat -n --color=always $realpath 2>/dev/null'
zstyle ':fzf-tab:complete:nvim:*' fzf-preview 'bat -n --color=always $realpath 2>/dev/null || cat $realpath'
zstyle ':fzf-tab:complete:vim:*' fzf-preview 'bat -n --color=always $realpath 2>/dev/null || cat $realpath'
zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' fzf-preview 'echo ${(P)word}'
zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview 'SYSTEMD_COLORS=1 systemctl status $word 2>/dev/null'
zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview 'git diff $word | bat -n --color=always -l diff 2>/dev/null'
zstyle ':fzf-tab:complete:git-log:*' fzf-preview 'git log --oneline --graph --color=always $word 2>/dev/null'
zstyle ':fzf-tab:complete:git-checkout:*' fzf-preview 'git log --oneline --graph --color=always $word 2>/dev/null'
zstyle ':fzf-tab:complete:docker-*:*' fzf-preview 'docker inspect $word 2>/dev/null | bat -n --color=always -l json'
zstyle ':fzf-tab:complete:kubectl-*:*' fzf-preview 'kubectl describe $word 2>/dev/null | head -40'
zstyle ':fzf-tab:*' fzf-flags --height=80% --layout=reverse --border
zstyle ':fzf-tab:*' switch-group '<' '>'

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
