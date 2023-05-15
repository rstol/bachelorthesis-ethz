# Use this configuration with the command ./scripts/run-image.sh run cached-nix-shell-cmd 'g++ -o hw_cpp hello_world.cpp && ./hw_cpp'
{ pkgs }:
{
  inputs = with pkgs;
 [
    autoconf
    automake
    bison
    flex
    binutils
    gdb
    libtool
    cmake
    strace
  ];
}