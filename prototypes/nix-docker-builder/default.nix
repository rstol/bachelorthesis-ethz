{ pkgs ? import <nixpkgs> { system = "x86_64-linux"; }
}:
let
  inherit (pkgs)
    runtimeShell
    dockerTools
    gzip
    lib
    writeScript
    skopeo
    stdenv
    mkShell
    ;

  localPath = ./workdir + "/local.nix";
  prefix = ./env;
  minimalBasePath = prefix + "/minimal-base.nix";
  presetPath = prefix + "/python.nix";

  hashes = (import ./nix/hash-files.nix { namePaths=[minimalBasePath presetPath]; tagPath = localPath; });
  imageName = hashes.nameHash;
  imageTag = hashes.tagHash;

  containerImage = let
    config = {
      Cmd = [ "/bin/sh" ];
      WorkingDir = "/home/user";
    };
    minimalBase = dockerTools.buildImage {
      name = "${imageName}-base";
      tag = "latest";
      contents = (import minimalBasePath).inputs
        ++ (import presetPath).inputs;
      inherit config;
    };
  in dockerTools.buildLayeredImage {
    name = imageName;
    tag = imageTag;
    fromImage = minimalBase;

    inherit config;

    contents = (import localPath).inputs;
    fakeRootCommands = ''
      #!${stdenv.shell}
      set -euo pipefail
      mkdir -p ./home/user
      chown --verbose -R 1000:1000 ./home/user
    '';
  };
in rec {
  push = pkgs.runCommand "push-layered-container-image-${imageTag}"
    {
      nativeBuildInputs = [ skopeo ];
    } ''
      #!${runtimeShell}
      set -eu

      # if [ -z "$DOCKER_ACCESS_TOKEN" ]; then
      #     echo "DOCKER_ACCESS_TOKEN not found in environment"
      #     exit 1
      # fi

      readonly imageUri="host.docker.internal:5000/${imageName}:${imageTag}"

      echo "Pushing $imageUri"
      skopeo copy \
        --quiet \
        --insecure-policy \
        --dest-tls-verify=false \
        --dest-creds "62r63d":"Jo1QGQbPYe5&w5" \
        "docker-archive:${containerImage}" \
        "docker://$imageUri"

      # declare -xp
      echo foo > $out
    '';
}
# rec {
#   inherit containerImage;
#   pushScript = writeScript "push-container-image-${imageTag}" ''
#     #!${stdenv.shell}
#     set -euo pipefail
#     readonly imageUri="host.docker.internal:5000/${containerImage.imageName}:${containerImage.imageTag}"
#     echo "Pushing $imageUri"
#     exec "${skopeo}/bin/skopeo" copy \
#     --quiet \
#     --insecure-policy \
#     --dest-creds "62r63d":"Jo1QGQbPYe5&w5" \
#     "docker-archive:${containerImage}" \
#     "docker://$imageUri"
#   '';

#   push = mkShell {
#     shellHook = ''
#       exec ${pushScript}
#     '';
#   };
# }