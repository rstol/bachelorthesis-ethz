with (import <nixpkgs> {});
{
  pythonEnv = python39.withPackages (p: with p; [
    matplotlib
    # other python packages
  ]);
  inputs = [
    pythonEnv

    curl
    python39Packages.matplotlib
  ];
  hooks = ''
    export FOO=bar
  '';
}