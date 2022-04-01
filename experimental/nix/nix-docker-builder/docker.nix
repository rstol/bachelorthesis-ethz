with (import <nixpkgs> { system = "x86_64-linux"; });
with builtins;
let
  localPath = ./workdir + "/local.nix";
  prefix = ./nix;
  minimalBasePath = prefix + "/minimal-base.nix";
  presetPath = prefix + "/python.nix";
in dockerTools.buildLayeredImage {
  name = hashString "md5" (foldl' (x: y: x + (hashFile "md5" y)) "" (sort lessThan [minimalBasePath presetPath]));
  tag = hashFile "md5" localPath;

  contents = (import localPath).inputs
        ++ (import minimalBasePath).inputs
        ++ (import presetPath).inputs;
  fakeRootCommands = ''
    mkdir -p ./home/user
    chown --verbose -R 1000:1000 ./home/user
  '';
  config = {
    Cmd = [
      "/bin/sh"
    ];
    WorkingDir = "/home/user";
  };
}