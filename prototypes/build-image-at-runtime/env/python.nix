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
    scikit-learn
    matplotlib
  ]);
in
{
  inputs = [
    ncurses
    bzip2
    openssl
    sqlite
    xz
    gcc

    pythonEnv
  ];
}