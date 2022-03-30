with (import <nixpkgs> { system = "x86_64-linux"; } );
let
  nixFromDockerHub = dockerTools.pullImage {
    imageName = "nixos/nix";
    imageDigest = "sha256:85299d86263a3059cf19f419f9d286cc9f06d3c13146a8ebbb21b3437f598357";
    sha256 = "19fw0n3wmddahzr20mhdqv6jkjn1kanh6n2mrr08ai53dr8ph5n7";
    finalImageTag = "2.2.1";
    finalImageName = "nix";
  };
in
  dockerTools.buildLayeredImage {
    name = "nix-builder";
    tag = "latest";

    fromImage = nixFromDockerHub;
    contents = [ gnused bash ];
    fakeRootCommands = ''
      mkdir -p ./home/user
    '';
    config= {
      Cmd = [
        "/bin/bash"
      ];
      WorkingDir = "/home/user";
      # Volumes = { "/nix" = { }; };
      # Entrypoint = "/home/user/nix-builder.sh";
    };
  }