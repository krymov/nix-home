{ config, lib, pkgs, ... }:

let
  cfg = config.nix-home.git;

  identities = {
    personal = { name = "Mark Krymov"; email = "mark@aipe.dev"; };
    agent = { name = "Claude Agent"; email = "agent@dalyoko.dev"; };
    custom = { name = cfg.name; email = cfg.email; };
  };
in {
  options.nix-home.git = {
    enable = lib.mkEnableOption "git configuration";

    identity = lib.mkOption {
      type = lib.types.enum [ "personal" "agent" "custom" ];
      default = "personal";
      description = "Git identity preset";
    };

    name = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Custom git user name (when identity = custom)";
    };

    email = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Custom git email (when identity = custom)";
    };

    signing = lib.mkEnableOption "GPG commit signing";

    signingKey = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "GPG key ID for commit signing";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.git = {
      enable = true;

      signing = lib.mkIf cfg.signing {
        key = cfg.signingKey;
        signByDefault = true;
      };

      settings = {
        user = {
          name = identities.${cfg.identity}.name;
          email = identities.${cfg.identity}.email;
        };
        core = {
          editor = "nvim";
          autocrlf = "input";
          quotepath = false;
          pager = "less -R";
        };
        pull.rebase = false;
        push = {
          default = "simple";
          followTags = true;
        };
        fetch.prune = true;
        init.defaultBranch = "main";
        merge = {
          conflictstyle = "zdiff3";
          tool = "nvim";
        };
        "mergetool \"nvim\"".cmd = "nvim -d $LOCAL $REMOTE $MERGED -c '$wincmd w' -c 'wincmd J'";
        diff = {
          colorMoved = "default";
          tool = "nvim";
        };
        "difftool \"nvim\"".cmd = "nvim -d $LOCAL $REMOTE";
        color = {
          ui = "auto";
          branch = { current = "yellow reverse"; local = "yellow"; remote = "green"; };
          diff = { meta = "yellow bold"; frag = "magenta bold"; old = "red bold"; new = "green bold"; };
          status = { added = "yellow"; changed = "green"; untracked = "cyan"; };
        };
        rerere.enabled = true;
        help.autocorrect = 1;
        credential.helper = "cache --timeout=3600";
        "url \"git@github.com:\"".insteadOf = "https://github.com/";
        "includeIf \"gitdir:~/\"".path = "~/.gitconfig.local";
        alias = {
          st = "status";
          ci = "commit";
          co = "checkout";
          br = "branch";
          lg = "log --oneline --graph --decorate";
          lga = "log --oneline --graph --decorate --all";
          ll = "log --pretty=format:\"%C(yellow)%h%Cred%d\\ %Creset%s%Cblue\\ [%cn]\" --decorate --numstat";
          lnc = "log --pretty=format:\"%h\\ %s\\ [%cn]\"";
          d = "diff";
          ds = "diff --staged";
          dc = "diff --cached";
          show-files = "show --pretty=\"\" --name-only";
          sl = "stash list";
          sa = "stash apply";
          ss = "stash save";
          unstage = "reset HEAD --";
          last = "log -1 HEAD";
          cleanup = "!git branch --merged | grep -v '\\\\*\\\\|main\\\\|master\\\\|develop' | xargs -n 1 git branch -d";
          ac = "!git add -A && git commit -m";
          undo = "reset --soft HEAD~1";
          recent-branches = "!git for-each-ref --count=10 --sort=-committerdate refs/heads/ --format='%(refname:short)'";
        };
      };

      ignores = [
        ".DS_Store" ".DS_Store?" "._*" ".Spotlight-V100" ".Trashes"
        "ehthumbs.db" "Thumbs.db"
        ".vscode/" ".idea/" "*.swp" "*.swo" "*~" ".vim/" ".nvim/"
        "*.tmp" "*.temp" "*.log" "*.pid" "*.seed" "*.pid.lock"
        ".env" ".env.local" ".env.*.local" ".envrc"
        "node_modules/" "npm-debug.log*" "yarn-debug.log*" "yarn-error.log*"
        "__pycache__/" "*.py[cod]" "*$py.class" "*.so" ".Python"
        "env/" "venv/" ".venv/" "pip-log.txt" "pip-delete-this-directory.txt" ".pytest_cache/"
        "target/"
        "vendor/" "*.test" "*.prof"
        "*.class" "*.jar" "*.war" "*.ear"
        "*.o" "*.a" "*.obj" "*.exe" "*.dll"
        "*.7z" "*.dmg" "*.gz" "*.iso" "*.rar" "*.tar" "*.zip"
        "*.sqlite" "*.db"
        "*.backup" "*.bak" "*.orig"
        ".local/" "local_settings.py" "settings_local.py"
        ".cache/" ".npm/" ".yarn/"
        "coverage/" ".coverage" ".nyc_output/" "htmlcov/"
        "docs/_build/" "site/"
        "*.egg-info/" "dist/" "build/"
        "*.patch" "*.diff"
        "*.pem" "*.key" "*.p12" "*.pfx" "secrets.json" "credentials.json"
        ".direnv/" ".nix-shell" ".nix-result" "result" "result-*"
        "**/.claude/settings.local.json"
      ];
    };
  };
}
