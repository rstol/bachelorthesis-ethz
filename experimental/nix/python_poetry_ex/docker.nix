let
  overlay = self: super: {
    imgapp = self.poetry2nix.mkPoetryApplication {
      projectDir = ./.;
      python = self.python3;
    };
  };
  localPkgs = import <nixpkgs> { overlays = [ overlay ]; };
  imagePkgs = import <nixpkgs> { overlays = [ overlay ]; system = "x86_64-linux"; };
in
{
  inherit (localPkgs) imgapp;

  docker = localPkgs.dockerTools.streamLayeredImage {
    name = "imgapp";
    contents = [ imagePkgs.imgapp ];
    config.Cmd = [ "imgapp" ];
  };

}
