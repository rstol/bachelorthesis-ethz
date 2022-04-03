with (import <nixpkgs> {});
let
  localPath = ./local.nix;

  packages = (import localPath).inputs;  # add user defined packages

  baseHooks = ''
    alias ll="ls -l"
    alias la="ls -A"
  '';

  shellHooks = baseHooks
    + lib.optionalString (builtins.pathExists localPath) (import localPath).hooks; # add user defined hooks

in mkShell {
  name = "python-env";
  buildInputs = packages;
  shellHook = shellHooks;
}