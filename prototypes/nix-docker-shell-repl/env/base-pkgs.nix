{ pkgs ? import <nixpkgs> { system = "x86_64-linux"; } }:
{
  inputs = with pkgs; [
    vim
    cached-nix-shell

    # used by nix-shell
    bashInteractive
    stdenv
  ];
}