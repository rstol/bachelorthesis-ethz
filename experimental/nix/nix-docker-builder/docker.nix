with (import <nixpkgs> { system = "x86_64-linux"; } );
let
  localPath = ./local.nix;
  minimalBasePath = ./minimal-base.nix;
  presetPath = ./python.nix;
in dockerTools.buildLayeredImage {
  name = "python39-extended";
  tag = "latest";

  contents = (import localPath).inputs
        ++ (import minimalBasePath).inputs
        ++ (import presetPath).inputs;
  fakeRootCommands = ''
    mkdir -p ./home/user
  '';
  config = {
    Cmd = [
      "/bin/bash"
    ];
    WorkingDir = "/home/user";
  };
}
