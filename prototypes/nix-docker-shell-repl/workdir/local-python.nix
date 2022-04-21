{ pkgs ? import <nixpkgs> { system = "x86_64-linux"; } }:
with pkgs;
let
  _python = pkgs.python39;
  pythonEnv = _python.withPackages (p: with p; [
    matplotlib
    # other python packages
  ]);
in {
  inputs = [
    curl

    pythonEnv
  ];
}