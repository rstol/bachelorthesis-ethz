with (import <nixpkgs> {});
let
  pythonEnv = python39.withPackages (p: with p; [
    matplotlib
    # other python packages
  ]);
in
{
  inputs = [
    pythonEnv
  ];
  hooks = ''
    export FOO=bar
  '';
}