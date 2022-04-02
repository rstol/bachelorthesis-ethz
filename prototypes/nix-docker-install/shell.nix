with (import <nixpkgs> {});
let
  localPath = ./local.nix;

  # _python = python39;

  # pythonEnv = _python.withPackages (p: with p; [
  #   pandas
  #   numpy
  #   requests
  #   # other python packages you want by default
  # ]);

  # defaultPkgs = [ coreutils bash vim ];
  packages = lib.optional (builtins.pathExists localPath) (import localPath).basePackages # add user defined packages
    # ++ defaultPkgsv
    # ++ [ pythonEnv ];

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