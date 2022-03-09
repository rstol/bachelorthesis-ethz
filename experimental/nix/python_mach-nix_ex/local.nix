with (import <nixpkgs> {});
{
  inputs = [ curl python39Packages.numpy bash nodejs-17_x];
  hooks = ''
    export FOO=bar
  '';
}