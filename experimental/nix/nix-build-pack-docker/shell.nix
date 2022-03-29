with (import <nixpkgs> {});
let
  localPath = ./local.nix;
  minimalBasePath = ./minimal-base.nix;
  presetPath = ./python.nix;
in
mkShell {
  name = "python-shell-env";
  buildInputs = (import localPath).inputs
        ++ (import minimalBasePath).inputs
        ++ (import presetPath).inputs;
}