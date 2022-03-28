  with (import <nixpkgs> { system = "x86_64-linux"; } );
  let
    localPath = ./local.nix;
    _python = pkgs.python39;
    pythonEnv = _python.withPackages (p: with p; [
      pandas
      numpy
      requests
      # other python packages in the minimal base image
    ]);
  in dockerTools.buildLayeredImage {
    name = "python39-extended";

    contents = [
      (buildEnv {
        name = "env";
        paths =  (import localPath).inputs ++ [
          coreutils
          bash
          vim
          which
          # other core packages

          pythonEnv
        ];
      })
    ];
    fakeRootCommands = ''
      mkdir -p ./home/user
    '';
    config = {
      Cmd = [
        "/bin/sh"
      ];
      WorkingDir = "/home/user";
    };
  }
