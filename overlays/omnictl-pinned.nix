final: prev:

let
  version = "1.4.7";

  srcs = {
    x86_64-linux = {
      url = "https://github.com/siderolabs/omni/releases/download/v${version}/omnictl-linux-amd64";
      sha256 = "f8d8c7679e0d5c2c17c5fd611d8b9ed9e7f202fe7d958b6402ae2864c3a433a9";
    };
    aarch64-linux = {
      url = "https://github.com/siderolabs/omni/releases/download/v${version}/omnictl-linux-arm64";
      sha256 = "33baeb7a541c8de6d583a5100050962b1f1de7f291d94508e99389ecf9176dc9";
    };
    aarch64-darwin = {
      url = "https://github.com/siderolabs/omni/releases/download/v${version}/omnictl-darwin-arm64";
      sha256 = "d6f5e3b5ffc4218dd12da115cc60bd01cb74d026fe1ed1fd7d05e4e01c67febe";
    };
  };

  src = srcs.${final.stdenv.hostPlatform.system}
    or (throw "omnictl: unsupported system ${final.stdenv.hostPlatform.system}");
in
{
  omnictl = final.stdenv.mkDerivation {
    pname = "omnictl";
    inherit version;

    src = final.fetchurl {
      inherit (src) url sha256;
    };

    dontUnpack = true;

    installPhase = ''
      install -Dm755 $src $out/bin/omnictl
    '';

    meta = with final.lib; {
      description = "CLI for Sidero Omni";
      homepage = "https://github.com/siderolabs/omni";
      license = licenses.bsl11;
      platforms = builtins.attrNames srcs;
    };
  };
}
