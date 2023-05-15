{ pkgs }:
{
  inputs = with pkgs; [
    coreutils-full
    bashInteractive
    curl
  ];
}