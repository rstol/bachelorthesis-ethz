{ pkgs }:
{
  inputs = with pkgs; [
    coreutils-full
    bashInteractive
    vim
    which
    curl
    findutils
    gnugrep
    man
  ];
}