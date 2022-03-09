# { pkgs ? import <nixpkgs> {} }:
# let
#   _pkgs = import ./poetry.nix { inherit pkgs; };
#   app = pkgs.poetry2nix.mkPoetryApplication {
#     projectDir = ./.;
#   };
# in pkgs.dockerTools.streamLayeredImage {
#   name = "imgapp";
#   contents = [ app.dependencyEnv ]; # environment with a python interpreter, all non-development dependencies and application
#   config.Cmd = [ "imgapp" ];
# }
{ pkgs ? import <nixpkgs> {} }:
pkgs.poetry2nix.mkPoetryApplication {
  projectDir = ./.;
}