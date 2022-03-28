with (import <nixpkgs> {});
let
  _python = pkgs.python3;
  pythonEnv = _python.withPackages (p: with p; [
    pandas
    requests
    # other python packages you want
  ]);
  basePackages = [ ripgrep ];
  packages = [ pythonEnv ]
    ++ basePackages;
in {
  name = "python-env";
  path = packages ++ basePackages;
}

