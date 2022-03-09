with (import <nixpkgs> {});
let
  _python = pkgs.python3;
  pythonEnv = _python.withPackages (p: with p; [
    pandas
    requests
    # other python packages you want
  ]);
  basePackages = [ ripgrep glibc ];
  packages = [ pythonEnv ]
    ++ basePackages;
in {
  name = "python-env";
  paths = [
    pkgs.hello
    pkgs.figlet
  ];
}

