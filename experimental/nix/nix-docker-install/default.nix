# default.nix
{ nixpkgs ? (import <nixpkgs> {}) }:

let
  stdenv = nixpkgs.stdenv;
  ghc = nixpkgs.haskellPackages.ghc;
in stdenv.mkDerivation rec {
  name = "python-env";
  version = "0.0.1";
  buildInputs = [
    ghc
  ];
}

# TODO
with (import <nixpkgs> {});
dockerTools.buildLayeredImage {
    name = "python-env";
    contents = [ (import ./default.nix).paths ];
    config = {
      Cmd = [
        "/bin/python3"
      ];
    };
}
