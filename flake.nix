{
  description = "Shared home-manager modules and packages for all machines";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, ... } @inputs:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"
      ];
      mkHome = { system, profile, username ? "mark", homeDirectory ? "/home/${username}" }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
            config.problems.handlers.pg_top.unsupported = "warn";
            overlays = [ self.overlays.unstable self.overlays.omnictl-pinned ];
          };
          modules = [
            ./default.nix
            {
              nix-home.profiles.${profile}.enable = true;
              home = {
                inherit username homeDirectory;
                stateVersion = "25.11";
              };
            }
          ];
        };
    in {
      homeManagerModules.default = import ./default.nix;

      homeConfigurations = {
        workspace = mkHome { system = "x86_64-linux"; profile = "workspace"; };
        personal = mkHome { system = "aarch64-darwin"; profile = "personal"; homeDirectory = "/Users/mark"; };
        agent = mkHome { system = "x86_64-linux"; profile = "agent"; };
        dev-agent = mkHome { system = "x86_64-linux"; profile = "dev-agent"; };
        server = mkHome { system = "x86_64-linux"; profile = "server"; };
      };

      # Package sets are lists (not derivations) — exposed as lib for consumer composition.
      # Usage: inputs.nix-home.lib.${system}.core  (list of packages)
      lib = forAllSystems (system:
        import ./packages {
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
            config.problems.handlers.pg_top.unsupported = "warn";
            overlays = [ self.overlays.omnictl-pinned ];
          };
        }
      );

      overlays.unstable = import ./overlays/unstable.nix { inherit inputs; };
      overlays.omnictl-pinned = import ./overlays/omnictl-pinned.nix;
    };
}
