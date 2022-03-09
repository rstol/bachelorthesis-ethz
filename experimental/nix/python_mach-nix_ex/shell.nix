with (import <nixpkgs> {});
let
  localPath = ./local.nix;
  inputs = [ (import ./default.nix ).path ]
    ++ lib.optional (builtins.pathExists localPath) (import localPath).inputs; # add user defined packages

  baseHooks = ''
    alias ll="ls -l"
    alias la="ls -A"
  '';

  shellHooks = baseHooks # add iser defined hooks
    + lib.optionalString (builtins.pathExists localPath) (import localPath).hooks;

in mkShell {
  name = "python-shell-env";
  buildInputs = inputs;
  shellHook = shellHooks;
}

