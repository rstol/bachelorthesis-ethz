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
    scikit-learn
    matplotlib
  ]);
in
{
  inputs = with pkgs; [
    pythonEnv
    # other packages
    curl
  ];
}