{ pkgs }:
{
  inputs = with pkgs; [
    gcc
    autoconf
    automake
    bison
    flex
    binutils
    gdb
    libtool
    cmake
    strace
    # large numerical library
    eigen
    # other packages
    curl
  ];
}