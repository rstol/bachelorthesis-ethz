{
  pkgs ? import <nixpkgs> {},
  localPath,
  presetPath
}:
with builtins;
let
  presetConfig = import presetPath { inherit pkgs; };
  localConfig = import localPath { inherit pkgs; };
in pkgs.mkShell {
  buildInputs = localConfig.inputs ++ presetConfig.inputs;
}