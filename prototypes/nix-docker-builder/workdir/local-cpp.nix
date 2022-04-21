{ pkgs }:
let
  # eigenDrv = pkgs.eigen.override {
  #   nativeBuildInputs = [ pkgs.makeWrapper ];

  #   postInstall = ''
  #       wrapProgram $out/bin/eigen3 \
  #           --set NIX_CFLAGS_COMPILE "$NIX_CFLAGS_COMPILE -I ${pkgs.eigen}/include/eigen3 "
  #     '';
  # };
in
{
  inputs = with pkgs; [
    curl
    # large numerical library
    gsl
    eigen
  ];
}