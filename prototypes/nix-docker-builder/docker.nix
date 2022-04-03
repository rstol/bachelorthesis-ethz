{ pkgs ? import <nixpkgs> { system = "x86_64-linux"; }, presetFile ? "/python.nix" }:
let
  inherit (pkgs)
    dockerTools
    gzip
    lib
    runCommand
    runtimeShell
    skopeo
    stdenv
    ;

  localPath = ./workdir + "/local.nix";
  prefix = ./env;
  minimalBasePath = prefix + "/minimal-base.nix";
  presetPath = prefix + presetFile;

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
      tag = imageTag;
      contents = (import minimalBasePath).inputs
        ++ (import presetPath).inputs;
      inherit config;
    };
  in {
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
in
pkgs.runCommand "push-streamed-container-image-${imageTag}"
{
  nativeBuildInputs = [ skopeo ];
} ''
  #!${runtimeShell}
  set -euo pipefail

  # if [ -z "$DOCKER_ACCESS_TOKEN" ]; then
  #     echo "DOCKER_ACCESS_TOKEN not found in environment"
  #     exit 1
  # fi

  readonly imageUri="62r63d/${imageName}:${imageTag}"

  echo "Pushing $imageUri"
  ${dockerTools.streamLayeredImage containerImage} | gzip --fast | skopeo copy \
    --quiet \
    --insecure-policy \
    --dest-creds "62r63d":"Jo1QGQbPYe5&w5" \
    "docker-archive:/dev/stdin" \
    "docker://$imageUri"
''