with (import <nixpkgs> { system = "x86_64-linux"; });
{
  inputs = [
    coreutils-full
    nix
    vim
    which
    bash
  ];
}