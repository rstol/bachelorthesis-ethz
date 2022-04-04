{ pkgs ? import <nixpkgs> { system = "x86_64-linux"; }, presetFile ? "/python.nix" }:
let
  inherit (pkgs) writeShellApplication dockerTools stdenv;
  prefix = ./env;
  minimalBasePath = prefix + "/minimal-base.nix";
  presetPath = prefix + presetFile;

  nixFromDockerHub = dockerTools.pullImage {
    imageName = "nixos/nix";
    imageDigest = "sha256:fc55b9bf9f61742a3fc262c0dc9ad62ea8ace014bb5bd4b11341da879e7b26ce"; # find this by instpecting the imageDigest of `docker pull nixos/nix`
    sha256 = "1fy8da8zvwa8cbiyl4zbb1zmyz4hadcbw3klav0bzvd55rpg335f"; # set to 0000..000 and then nix will tell you the sha when building the first time
    finalImageTag = "2.7.0";
    finalImageName = "nix";
  };

  hashes = (import ./nix/hash-files.nix { namePaths=[minimalBasePath presetPath]; });
  imageName = hashes.nameHash;
in
dockerTools.buildLayeredImage {
  name = imageName;
  tag = "latest";
  # fromImage = nixFromDockerHub;

  contents = (import minimalBasePath).inputs
        ++ (import presetPath).inputs;
  fakeRootCommands = ''
      #!${stdenv.shell}
      set -euo pipefail
      mkdir -p ./home/user
      chown --verbose -R 1000:1000 ./home/user
  '';
  maxLayers=120; # fromImage already has 101 layers
  config = {
    Cmd = [ "/bin/sh" ];
    WorkingDir = "/home/user";
    Volumes = { "/nix" = {}; };
    Env = [
      # nix-store uses cat program to display results as specified by
      # the image env variable NIX_PAGER.
      "NIX_PAGER=cat"
      # A user is required by nix
      # https://github.com/NixOS/nix/blob/9348f9291e5d9e4ba3c4347ea1b235640f54fd79/src/libutil/util.cc#L478
      "USER=user"
    ];
  };
}