{ pkgs, python ? pkgs.python39 }:
with pkgs;
let
  _python = python; # the python version should be specified by the user
  pythonEnv = _python.withPackages (p: with p; [
    scipy
    # numpy
    pandas
    termcolor
    networkx
    gnureadline
    jinja2
    scikit-learn
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