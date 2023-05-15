{ pkgs }:
with pkgs;
let
  _python = pkgs.python39; # the python version should be specified by the user
  pythonEnv = _python.withPackages (p: with p; [
    numpy
    scipy
  ]);
in
{
  inputs = [
    pythonEnv
  ];
}