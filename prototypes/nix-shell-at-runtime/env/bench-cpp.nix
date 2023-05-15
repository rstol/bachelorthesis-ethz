{ pkgs }:
{
  inputs = with pkgs; [
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
  ];
}