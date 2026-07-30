# herdr is not in nixpkgs — it ships its own flake. We take the prebuilt
# package output rather than upstream's overlays.default, because that one
# composes rust-overlay into our nixpkgs (dragging rust-bin/toolchain attrs
# into every pkgs set that uses it).
{ inputs }:
final: prev: {
  herdr = inputs.herdr.packages.${final.stdenv.hostPlatform.system}.herdr;
}
