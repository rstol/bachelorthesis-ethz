{ pkgs ? import <nixpkgs> {} }:
with pkgs;
let
  _python = pkgs.python39;
  pythonEnv = _python.withPackages (p: with p; [
    matplotlib
    # other python packages
  ]);
in {
  inputs = [
    pythonEnv
  ];

  hooks = ''
    alias la="ls -A"
  '';
}