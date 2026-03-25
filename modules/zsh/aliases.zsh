# Dotfiles management
alias dotup='home-manager switch'

# Directory navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# List files (eza if available, otherwise ls)
if command -v eza >/dev/null; then
  alias ls='eza'
  alias ll='eza -lh --git'
  alias la='eza -lah --git'
  alias lt='eza --tree'
else
  alias ll='ls -lh'
  alias la='ls -lah'
fi

# Git
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'
alias glog='git log --oneline --graph --decorate'

# Lazygit
if command -v lazygit >/dev/null; then
  alias lg='lazygit'
fi

# Kubernetes
if command -v kubectl >/dev/null; then
  alias k='kubectl'
  alias kgp='kubectl get pods'
  alias kgs='kubectl get services'
  alias kgd='kubectl get deployments'
  alias kga='kubectl get all'
  alias kaf='kubectl apply -f'
  alias kdf='kubectl delete -f'
  alias kns='kubectl config set-context --current --namespace'
fi

# Google Cloud
if command -v gcloud >/dev/null; then
  alias gce='gcloud compute'
  alias gcssh='gcloud compute ssh'
  alias gcpl='gcloud projects list'
fi

# Docker
if command -v docker >/dev/null; then
  alias dps='docker ps'
  alias dpa='docker ps -a'
  alias di='docker images'
  alias dexec='docker exec -it'
  alias dlog='docker logs'
fi

# Terraform
if command -v terraform >/dev/null; then
  alias tf='terraform'
  alias tfi='terraform init'
  alias tfp='terraform plan'
  alias tfa='terraform apply'
  alias tfv='terraform validate'
fi

# Helm
if command -v helm >/dev/null; then
  alias hl='helm list'
  alias hi='helm install'
  alias hu='helm upgrade'
fi

# tmux
alias ta='tmux attach'
alias tl='tmux list-sessions'

# System
alias grep='grep --color=auto'

# Platform-specific
case "$PLATFORM" in
  "macos")
    alias o='open'
    ;;
  "nixos"|"linux")
    alias o='xdg-open'
    if command -v xclip >/dev/null; then
      alias pbcopy='xclip -selection clipboard'
      alias pbpaste='xclip -selection clipboard -o'
    fi
    if [[ "$PLATFORM" == "nixos" ]]; then
      alias nrs='sudo nixos-rebuild switch'
      alias nrt='sudo nixos-rebuild test'
    fi
    ;;
esac

# direnv
alias da='direnv allow'
alias dr='direnv reload'

# Nix development
alias ndev='nix develop'
alias nflake='nix flake'
alias ncheck='nix flake check'
alias nupdate='nix flake update'
alias nbuild='nix build'

# Python workflow
alias lint='ruff check .'
alias format='ruff format .'
