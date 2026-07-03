{ config, lib, pkgs, ... }:

let cfg = config.nix-home.starship;
in {
  options.nix-home.starship = {
    enable = lib.mkEnableOption "starship prompt";
  };

  config = lib.mkIf cfg.enable {
    # Identity helpers for the cloud/secrets custom modules (gated + prod-aware).
    home.file.".config/starship/aws.sh" = { source = ../scripts/starship-aws.sh; executable = true; };
    home.file.".config/starship/gcloud.sh" = { source = ../scripts/starship-gcloud.sh; executable = true; };
    home.file.".config/starship/vault.sh" = { source = ../scripts/starship-vault.sh; executable = true; };

    programs.starship = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        add_newline = false;
        # Two-line: dense context up top (length doesn't matter — you don't type
        # there), then the cursor alone on the line below.
        format = "$hostname$directory$git_branch$git_status\${custom.aws}\${custom.aws_prod}\${custom.gcloud}\${custom.gcloud_prod}$azure$terraform\${custom.vault}\${custom.vault_prod}$kubernetes$cmd_duration\${custom.env_prod}\${custom.env_staging}$line_break$character";

        # Host: only when remote, so multiplexed panes reveal which box they sit on.
        hostname = {
          ssh_only = true;
          format = "[$hostname]($style) ";
          style = "bold blue";
        };

        directory = {
          truncation_length = 3;
          truncate_to_repo = true;
        };

        git_branch = {
          format = "[$branch]($style) ";
          style = "bold purple";
        };

        git_status = {
          format = "[$all_status$ahead_behind]($style) ";
          style = "bold red";
        };

        cmd_duration = {
          min_time = 2000;
          format = "[$duration]($style) ";
          style = "bold yellow";
        };

        character = {
          success_symbol = "[>](bold green)";
          error_symbol = "[>](bold red)";
        };

        # Kube — the blast-radius signal. Shows context AND namespace (what a
        # kubectl actually hits). Native module — reads kubeconfig, no subprocess.
        # Prod contexts go red, staging yellow; edit context_pattern to taste.
        kubernetes = {
          disabled = false;
          format = "[$symbol$context(:$namespace)]($style) ";
          symbol = "⎈ ";
          style = "cyan";
          contexts = [
            # prod/staging match first and stay full + colored for visibility.
            { context_pattern = ".*(prod|prd).*"; style = "bold red"; symbol = "⎈ "; }
            { context_pattern = ".*(stag|stg).*"; style = "bold yellow"; symbol = "⎈ "; }
            # Everything else: shorten GKE gke_PROJECT_REGION_CLUSTER → PROJECT/CLUSTER.
            { context_pattern = "gke_(?P<proj>[^_]+)_[^_]+_(?P<cluster>.+)"; context_alias = "$proj/$cluster"; }
          ];
        };

        # Host blast-radius (HOST_ENV), gated so dev shows nothing. Source of truth
        # that travels: a pane SSH'd into a prod box sees that box's HOST_ENV=prod.
        custom.env_prod = {
          when = ''test "$HOST_ENV" = prod'';
          format = "[⚠ PROD]($style) ";
          style = "bold red";
          shell = [ "sh" ];
        };
        custom.env_staging = {
          when = ''test "$HOST_ENV" = staging'';
          format = "[⚠ STG]($style) ";
          style = "bold yellow";
          shell = [ "sh" ];
        };

        # Cloud/secrets identity via custom modules: gated (hidden until an identity
        # is actually assumed — native aws leaks a lone icon when only AWS_REGION is
        # set) and prod-aware (native modules can't color-by-value). Each provider
        # has a normal + prod variant with mutually-exclusive `when`; helper scripts
        # in ~/.config/starship print the identity.
        custom.aws = {
          when = ''v=$($HOME/.config/starship/aws.sh); [ -n "$v" ] && ! printf "%s" "$v" | grep -qiE "prod|prd"'';
          command = "$HOME/.config/starship/aws.sh";
          format = "[ $output]($style) ";
          style = "bold yellow";
          shell = [ "sh" ];
        };
        custom.aws_prod = {
          when = ''$HOME/.config/starship/aws.sh | grep -qiE "prod|prd"'';
          command = "$HOME/.config/starship/aws.sh";
          format = "[ $output ⚠]($style) ";
          style = "bold red";
          shell = [ "sh" ];
        };
        custom.gcloud = {
          when = ''v=$($HOME/.config/starship/gcloud.sh); [ -n "$v" ] && ! printf "%s" "$v" | grep -qiE "prod|prd"'';
          command = "$HOME/.config/starship/gcloud.sh";
          format = "[ $output]($style) ";
          style = "bold blue";
          shell = [ "sh" ];
        };
        custom.gcloud_prod = {
          when = ''$HOME/.config/starship/gcloud.sh | grep -qiE "prod|prd"'';
          command = "$HOME/.config/starship/gcloud.sh";
          format = "[ $output ⚠]($style) ";
          style = "bold red";
          shell = [ "sh" ];
        };
        azure = {
          disabled = false;
          format = "[$symbol$subscription]($style) ";
          symbol = "󰠅 ";
          style = "bold cyan";
        };

        # Terraform — which workspace an apply would hit (blast radius). Workspace
        # only, so no slow `terraform version` shell-out. Shows in .tf dirs.
        terraform = {
          disabled = false;
          format = "[$symbol$workspace]($style) ";
          symbol = "󱁢 ";
          style = "bold #cba6f7";
        };

        # Vault / OpenBao — which secrets store you're pointed at (VAULT_ADDR /
        # BAO_ADDR, host only). Prod addr → red ⚠.
        custom.vault = {
          when = ''v=$($HOME/.config/starship/vault.sh); [ -n "$v" ] && ! printf "%s" "$v" | grep -qiE "prod|prd"'';
          command = "$HOME/.config/starship/vault.sh";
          format = "[󰌾 $output]($style) ";
          style = "bold #f38ba8";
          shell = [ "sh" ];
        };
        custom.vault_prod = {
          when = ''$HOME/.config/starship/vault.sh | grep -qiE "prod|prd"'';
          command = "$HOME/.config/starship/vault.sh";
          format = "[󰌾 $output ⚠]($style) ";
          style = "bold red";
          shell = [ "sh" ];
        };

        # Language/toolchain modules stay off — nix + direnv own the environment.
        docker_context.disabled = true;
        nodejs.disabled = true;
        python.disabled = true;
        rust.disabled = true;
        golang.disabled = true;
        java.disabled = true;
        dotnet.disabled = true;
        package.disabled = true;
      };
    };
  };
}
