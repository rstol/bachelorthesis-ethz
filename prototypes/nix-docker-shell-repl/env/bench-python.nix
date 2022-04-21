{ pkgs ? import <nixpkgs> { system = "x86_64-linux"; } }:
with pkgs;
let
  _python = pkgs.python39; # the python version should be specified by the user
  pythonEnv = _python.withPackages (p: with p; [
    numpy
  ]);
in
{
  inputs = [
    pythonEnv
  ];
}