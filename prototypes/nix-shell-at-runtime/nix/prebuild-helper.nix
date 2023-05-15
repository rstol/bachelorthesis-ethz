{ presetConfig, baseConfig }:
with builtins;
let
  pkgs = import (import ./sources.nix).nixpkgs {};
  presetConfigPath = import (/. + presetConfig) { inherit pkgs; };
  baseConfigPath = import (/. + baseConfig) { inherit pkgs; };
in {
  inputs = baseConfigPath.inputs ++ presetConfigPath.inputs;
}
