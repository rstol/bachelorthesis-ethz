with (import <nixpkgs> { system = "x86_64-linux"; });
with builtins;
let
  localPath = ./workdir + "/local.nix";
  prefix = ./nix;
  minimalBasePath = prefix + "/minimal-base.nix";
  presetPath = prefix + "/python.nix";

  imageName = hashString "md5" (foldl' (x: y: x + (hashFile "md5" y)) "" (sort lessThan [minimalBasePath presetPath]));
  imageTag = hashFile "md5" localPath;

  containerImage = let
    config = {
      Cmd = [ "/bin/sh" ];
      WorkingDir = "/home/user";
    };
    minimalBase = dockerTools.buildLayeredImage {
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
  set -Eeuo pipefail

  # if [ -z "$DOCKER_ACCESS_TOKEN" ]; then
  #     echo "DOCKER_ACCESS_TOKEN not found in environment"
  #     exit 1
  # fi

  readonly imageUri="localhost:5000/${imageName}:${imageTag}"

  echo "Pushing $imageUri"
  ${dockerTools.streamLayeredImage containerImage} | gzip --fast | skopeo copy \
    --quiet \
    --insecure-policy \
    --dest-creds "62r63d":"Jo1QGQbPYe5&w5" \
    "docker-archive:/dev/stdin" \
    "docker://$imageUri"
''