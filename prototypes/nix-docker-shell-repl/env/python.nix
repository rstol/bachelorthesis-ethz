{ pkgs ? import <nixpkgs> { system = "x86_64-linux"; },
  python ? pkgs.python39
}:
with pkgs;
let
  pythonEnv = python.withPackages (p: with p; [
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