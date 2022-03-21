with (import <nixpkgs> {});
{
  basePackages = [ curl python39Packages.matplotlib ];
  pythonPackages = python39.withPackages (p: with p; [
    pandas
    numpy
    requests
    # other python packages you want by default
  ]);
  hooks = ''
    export FOO=bar
  '';
}