with (import <nixpkgs> {});
{
  inputs = [ curl python39Packages.numpy nodejs-17_x];
  hooks = ''
    export FOO=bar
  '';
}