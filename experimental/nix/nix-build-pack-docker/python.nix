with (import <nixpkgs> {});
let
  _python = pkgs.python39;
  pythonEnv = _python.withPackages (p: with p; [
    numpy
    pandas
    # other python packages in the minimal base image
  ]);
in { inputs = [pythonEnv]; }