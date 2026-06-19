# Shell functions

# Terminal/pane title — user@host:dir. Lets tmux's pane-border #T reflect the
# REMOTE host after an ssh, so each pane shows which box it's actually on.
_set_title() { print -Pn "\e]2;%n@%m: %~\a"; }
autoload -Uz add-zsh-hook && add-zsh-hook precmd _set_title

# Timewarrior context tags (local only; the laptop is the single source of truth).
# chpwd: re-evaluate the active project when you cd to a different repo within a
# pane (tmux can't see this) — re-tracks only on project change, no churn.
_timew_focus() {
  [[ -n "$TMUX" && -z "$SSH_CONNECTION" ]] || return
  command -v timew >/dev/null 2>&1 || return
  local s; s=$(tmux display-message -p '#S' 2>/dev/null)
  ~/.config/tmux/timew-focus.sh "$s" "$PWD" >/dev/null 2>&1
}
add-zsh-hook chpwd _timew_focus

# preexec: when you run `ssh <host>`, tag the active interval host:<target>, so a
# work block records which boxes it touched (captured from the local side).
_timew_ssh() {
  [[ -z "$SSH_CONNECTION" ]] || return
  command -v timew >/dev/null 2>&1 || return
  [[ "$1" == ssh\ * ]] || return
  [[ "$(timew get dom.active 2>/dev/null)" == 1 ]] || return
  local host
  host=$(printf '%s\n' "$1" | awk '{for(i=2;i<=NF;i++){if($i ~ /^-/){i++; continue} print $i; exit}}')
  host=${host#*@}
  [[ -n "$host" ]] && timew tag @1 "host:$host" >/dev/null 2>&1
}
add-zsh-hook preexec _timew_ssh

# Create and enter directory
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# Extract various archive formats
extract() {
  if [[ -f "$1" ]]; then
    case "$1" in
      *.tar.bz2)   tar xjf "$1"   ;;
      *.tar.gz)    tar xzf "$1"   ;;
      *.bz2)       bunzip2 "$1"   ;;
      *.rar)       unrar x "$1"   ;;
      *.gz)        gunzip "$1"    ;;
      *.tar)       tar xf "$1"    ;;
      *.tbz2)      tar xjf "$1"   ;;
      *.tgz)       tar xzf "$1"   ;;
      *.zip)       unzip "$1"     ;;
      *.Z)         uncompress "$1";;
      *.7z)        7z x "$1"      ;;
      *.xz)        unxz "$1"      ;;
      *.lzma)      unlzma "$1"    ;;
      *)           echo "'$1' cannot be extracted" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# Change to git root directory
cdgit() {
  local git_root
  git_root=$(git rev-parse --show-toplevel 2>/dev/null)
  if [[ -n "$git_root" ]]; then
    cd "$git_root"
  else
    echo "Not in a git repository"
    return 1
  fi
}

# Quick tmux session management
tn() {
  local session_name="${1:-$(basename "$PWD")}"
  tmux new-session -d -s "$session_name" 2>/dev/null || tmux attach-session -t "$session_name"
}

# Kill tmux session
tk() {
  local session_name="${1:-$(tmux display-message -p '#S')}"
  tmux kill-session -t "$session_name"
}

# Clean merged git branches
unalias gclean 2>/dev/null
gclean() {
  git branch --merged | grep -v "\*\|main\|master\|develop" | xargs -n 1 git branch -d
}

# Quick HTTP server
serve() {
  local port="${1:-8000}"
  python3 -m http.server "$port"
}

# Get public IP
myip() {
  curl -s https://ipinfo.io/ip
}

# Kubernetes context/namespace switching with fzf
kctx() {
  local context
  context=$(kubectl config get-contexts -o name | fzf --prompt="Context: ")
  [[ -n "$context" ]] && kubectl config use-context "$context"
}

knsf() {
  local namespace
  namespace=$(kubectl get namespaces -o name | sed 's/namespace\///' | fzf --prompt="Namespace: ")
  [[ -n "$namespace" ]] && kubectl config set-context --current --namespace="$namespace"
}

# GCP project switching with fzf
gcproj() {
  local project
  project=$(gcloud projects list --format="value(projectId)" | fzf --prompt="GCP project: ")
  [[ -n "$project" ]] && gcloud config set project "$project"
}

# AWS profile switching with fzf
awsprof() {
  local profile
  profile=$(aws configure list-profiles | fzf --prompt="AWS profile: ")
  [[ -n "$profile" ]] && export AWS_PROFILE="$profile"
}

# Load machine-specific functions if they exist
[[ -r "$HOME/.zsh/functions.local.zsh" ]] && source "$HOME/.zsh/functions.local.zsh"

# Install zsh completion for any tool
zsh-comp() {
  local cmd="$1"
  local dir="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/completions"
  mkdir -p "$dir"

  if [[ -z "$cmd" ]]; then
    echo "Usage: zsh-comp <command> [generator-args]"
    echo "  zsh-comp kubectl              # tries: kubectl completion zsh"
    echo "  zsh-comp rustup               # tries: rustup completions zsh"
    echo "  zsh-comp my-tool --gen-zsh    # custom: my-tool --gen-zsh"
    echo "\nInstalled:" && ls "$dir" 2>/dev/null
    return
  fi

  shift
  local out="$dir/_$cmd"

  if [[ $# -gt 0 ]]; then
    "$cmd" "$@" > "$out" 2>/dev/null
  else
    "$cmd" completion zsh > "$out" 2>/dev/null ||
    "$cmd" completions zsh > "$out" 2>/dev/null ||
    "$cmd" --zsh-completion > "$out" 2>/dev/null ||
    { echo "Couldn't auto-detect. Use: zsh-comp $cmd <args-to-generate>"; rm -f "$out"; return 1; }
  fi

  echo "Installed: $out"
  echo "Run 'compinit' or restart shell to activate"
}
