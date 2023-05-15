{
  sources ? import ./sources.nix,
  userConfigPath
}:
let
  pkgs = import sources.nixpkgs-unstable {};
  userConfig = import userConfigPath { inherit pkgs; };
in pkgs.mkShell {
  inputsFrom = [];
  buildInputs = userConfig.inputs;
  shellHook = userConfig.shellHook;
}