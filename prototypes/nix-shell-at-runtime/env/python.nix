{ pkgs }:
with pkgs;
let
  pythonEnv = python39.withPackages (p: with p; [
    scipy
    numpy
    pandas
    termcolor
    networkx
    gnureadline
    jinja2
    matplotlib
  ]);
in
{
  inputs = [
    pythonEnv
  ];

  shellHook = "";
}