{ pkgs }:
{
  inputs = with pkgs;
 [
    autoconf
    automake
    gcc
    bison
    flex
    binutils
    gdb
    glibc
    libtool
    cmake
    strace
  ];
}