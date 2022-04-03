with (import <nixpkgs> { system = "x86_64-linux"; });
let
  _python = pkgs.python39; # the python version should be specified by the user
  pythonEnv = _python.withPackages (p: with p; [
    scipy
    numpy
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