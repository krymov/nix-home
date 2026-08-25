# secretspec pinned ahead of nixpkgs. Upstream ships no flake (only devenv.nix +
# Cargo.toml), so we can't take a package output the way overlays/herdr.nix does.
# Instead we rebuild the nixpkgs Rust derivation at a specific crates.io release.
# Bump: version + src hash (nix build reports it) + cargoDeps vendor hash
# (set to lib.fakeHash, build once, copy the reported hash).
{ inputs }:
final: prev:
let
  unstable = import inputs.nixpkgs-unstable {
    system = final.stdenv.hostPlatform.system;
  };
in
{
  secretspec = (prev.secretspec.override { rustPlatform = unstable.rustPlatform; }).overrideAttrs (old: rec {
    version = "0.17.0";
    src = final.fetchCrate {
      pname = "secretspec";
      inherit version;
      hash = "sha256-3UW0j5i+2r8yWaYYCtbdtiPJe8epLKeR1cpP35Bxko4=";
    };
    # Override the vendor FOD directly; overrideAttrs on cargoHash does not
    # reliably re-thread through buildRustPackage's finalAttrs form.
    cargoDeps = final.rustPlatform.fetchCargoVendor {
      inherit src;
      name = "secretspec-${version}-vendor";
      hash = "sha256-I6HFcWPB5TUSMtnk+SEHMxiKlPBxHLrj8zgzEWllV2w=";
    };
    # Upstream lib tests include_str! a schema file that crates.io does not ship in
    # the published .crate, so the test target fails to compile. We package the
    # binary, not run upstream's tests — skip the checkPhase.
    doCheck = false;
  });
}
