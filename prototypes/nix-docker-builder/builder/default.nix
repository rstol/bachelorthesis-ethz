{ pkgs ? import <nixpkgs> { system = "x86_64-linux"; }
}:
let
  inherit (pkgs) writeScript dockerTools  skopeo stdenv;

  nixFromDockerHub = dockerTools.pullImage {
    imageName = "nixos/nix";
    imageDigest = "sha256:fc55b9bf9f61742a3fc262c0dc9ad62ea8ace014bb5bd4b11341da879e7b26ce"; # find this by instpecting the imageDigest of `docker pull nixos/nix`
    sha256 = "1fy8da8zvwa8cbiyl4zbb1zmyz4hadcbw3klav0bzvd55rpg335f"; # set to 0000..000 and then nix will tell you the sha when building the first time
    finalImageTag = "2.7.0";
    finalImageName = "nix";
  };

  entrypoint = writeScript "entrypoint.sh" ''
    #!${stdenv.shell}
    set -e
    echo "hello"
    if [ "$1" = 'streamed' ]; then
      exec nix-build docker.nix -A push --no-out-link
    fi
    if [ "$1" = 'layered' ]; then
      exec nix-build -A push --no-out-link
    fi
    if [ "$1" = 'sh' ]; then
      exec /bin/sh
    fi
    exec "$@"
  '';

in rec {
  image = dockerTools.buildLayeredImage {
    name = "nix-builder";
    tag = "latest";

    maxLayers=120; # fromImage already has 101 layers
    fromImage = nixFromDockerHub;
    contents = [ skopeo ];
    fakeRootCommands = ''
      mkdir -p ./home/user
    '';
    config= {
      Cmd = [ "/bin/sh" ];
      Entrypoint = [ entrypoint ];
      WorkingDir = "/home/user";
      Env = [
        "DOCKER_ACCESS_TOKEN=Jo1QGQbPYe5&w5"
      ];
      Volumes = { "/nix" = {}; };
    };
  };
}