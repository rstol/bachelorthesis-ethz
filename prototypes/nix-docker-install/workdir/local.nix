with (import <nixpkgs> {});
let
  pythonEnv = python39.withPackages (p: with p; [
    matplotlib
    requests
    # other python packages
  ]);
in
{
  inputs = [
    python39Packages.matplotlib
    python39Packages.requests
  ];
  hooks = ''
    export FOO=bar
  '';
}