{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
    nativeBuildInputs = [ pkgs.rustc pkgs.cargo pkgs.nodejs-16_x ];
}
