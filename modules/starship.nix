{ config, lib, pkgs, ... }:

let cfg = config.nix-home.starship;
in {
  options.nix-home.starship = {
    enable = lib.mkEnableOption "starship prompt";
  };

  config = lib.mkIf cfg.enable {
    programs.starship = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        add_newline = false;
        # Left = where you type: host, dir, git, danger. Kube + duration go right.
        format = "$hostname$directory$git_branch$git_status$custom$character";
        right_format = "$cmd_duration$kubernetes";

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

        # Kube-context per pane. Native module — reads kubeconfig, no kubectl subprocess.
        # Prod contexts go red, staging yellow; edit context_pattern to taste.
        kubernetes = {
          disabled = false;
          format = "[$symbol$context]($style) ";
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

        aws.disabled = true;
        gcloud.disabled = true;
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
