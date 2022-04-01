with (import <nixpkgs> {});
let
  _python = pkgs.python39;
  pythonEnv = _python.withPackages (p: with p; [
    matplotlib
    # other python packages in the minimal base image
  ]);
in { inputs = [ curl pythonEnv]; }