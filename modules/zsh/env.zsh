# Environment variables
# NOTE: EDITOR, VISUAL, PAGER, LESS are set by Home Manager (sessionVariables)
# NOTE: bat, ripgrep, fzf are configured by Home Manager (programs.*)

# Locale
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

export MANPAGER="nvim +Man!"
export COLORTERM="truecolor"
export LESSOPEN="|bat --color=always %s 2>/dev/null || cat %s"

# GPG TTY (for git signing)
export GPG_TTY=$(tty)

# Platform-specific
case "$PLATFORM" in
  "macos")
    export BROWSER="open"
    ;;
  "nixos"|"linux")
    export BROWSER="firefox"
    export MOZ_ENABLE_WAYLAND=1
    export QT_QPA_PLATFORM=wayland
    export GDK_BACKEND=wayland
    ;;
esac

# Python
export PYTHONDONTWRITEBYTECODE=1
export PYTHONUNBUFFERED=1

# Rust
if [[ -d "$HOME/.cargo" ]]; then
  export PATH="$HOME/.cargo/bin:$PATH"
fi

# Go
if command -v go >/dev/null; then
  export GOPATH="$HOME/go"
  export PATH="$GOPATH/bin:$PATH"
fi

# Docker
if command -v docker >/dev/null; then
  export DOCKER_BUILDKIT=1
  export COMPOSE_DOCKER_CLI_BUILD=1
fi

# Terraform
if command -v terraform >/dev/null; then
  export CHECKPOINT_DISABLE=1
fi

# AWS
if command -v aws >/dev/null; then
  export AWS_PAGER=""
fi
