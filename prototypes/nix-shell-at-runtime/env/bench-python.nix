{ pkgs }:
let
  pythonEnv = with pkgs; python39.withPackages (p: with p; [
    scipy
    numpy
    pandas
    termcolor
    networkx
    gnureadline
    jinja2
    matplotlib
    # difference from "python.nix" python packages
    scikit-learn
  ]);
in
{
  inputs = with pkgs; [
    pythonEnv
    # other packages
    ncurses
    bzip2
    openssl
    sqlite
    xz
  ];
}