{ pkgs ? import <nixpkgs> { system = "x86_64-linux"; }
}:
with builtins;
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
    bashInteractive
    pigz
    ;

  config = fromJSON (readFile ./config.json);
  hashF = import ./nix/hash-files.nix;
  basePath = ./. + config.baseConfig.path;
  presetPaths = map (x: ./. + x.path) config.userConfig;
  validPath = x: lib.strings.hasSuffix ".nix" (toString x) && pathExists x;
  # make local and preset nix configuration optional
  existingPresets = concatMap (x: lib.lists.optional (validPath x) x) presetPaths;
  imageName = hashF basePath;
  imageTag = hashF existingPresets;
  imageDest = "${config.env.DOCKER_REGISTRY_CONTAINER}/${imageName}:${imageTag}";

  containerImage = let
    config = {
      Cmd = [ "${bashInteractive}/bin/bash" ];
      WorkingDir = "/home/user";
    };
    minimalBase = dockerTools.buildImage {
      name = "${imageName}-base";
      tag = "latest";
      inherit config;
      contents = (import basePath { inherit pkgs; }).inputs;
    };
  in  {
    tag = imageTag;
    name = imageName;
    fromImage = minimalBase;

    inherit config;

    contents = concatMap (x: (import x { inherit pkgs; }).inputs) existingPresets;
    fakeRootCommands = ''
      #!${stdenv.shell}
      set -euo pipefail
      mkdir -p ./home/user
      chown --verbose -R 1000:1000 ./home/user
    '';
  };
in rec {
  push-layered = pkgs.runCommand "push-layered-container-image-${imageTag}"
    {
      nativeBuildInputs = [ skopeo ];
      sourceURL = "docker-archive:${dockerTools.buildLayeredImage containerImage}";
    } ''
      #!${runtimeShell}
      set -eu
      echo "Pushing ${imageDest}"

      # remote Docker hub needs this flag for authentication: --dest-creds=<username>:<password> \
      skopeo copy \
        --quiet \
        --insecure-policy \
        --dest-tls-verify=false \
        "$sourceURL" \
        "docker://${imageDest}"

      # declare -xp
      echo foo > $out
    '';
  push-streamed = pkgs.runCommand "push-streamed-container-image-${imageTag}"
    {
      nativeBuildInputs = [ skopeo pigz ];
    } ''
      #!${runtimeShell}
      set -eu
      echo "Pushing ${imageDest}"

      # remote Docker hub needs this option for auth: --dest-creds=<username>:<password> \
      ${dockerTools.streamLayeredImage containerImage} \
        | pigz -T \
        | skopeo copy \
          --quiet \
          --insecure-policy \
          --dest-tls-verify=false \
          "docker-archive:/dev/stdin" \
          "docker://${imageDest}"

      echo foo > $out
    '';
}