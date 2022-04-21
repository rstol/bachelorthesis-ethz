{ pkgs ? import <nixpkgs> { system = "x86_64-linux"; } }:
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