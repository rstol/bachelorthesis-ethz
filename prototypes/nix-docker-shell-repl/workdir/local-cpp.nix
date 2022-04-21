{ pkgs ? import <nixpkgs> { system = "x86_64-linux"; } }:
let
in
{
  inputs = with pkgs; [
    curl
    # large numerical library
    gsl
    eigen
  ];
}