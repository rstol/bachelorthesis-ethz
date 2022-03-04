# { pkgs ? import <nixpkgs> {} }:

# pkgs.mkShell {
#   buildInputs = [
#     pkgs.python3
#     pkgs.poetry
#   ];
# }

let
  pkgs = import <nixpkgs> {};
  app = pkgs.poetry2nix.mkPoetryEnv {
    projectDir = ./.;
    editablePackageSources.imgapp = ./.;
  };
in pkgs.mkShell { buildInputs = [ app pkgs.poetry ]; }
