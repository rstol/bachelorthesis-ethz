{
  sources ? import nix/sources.nix,
  pkgs ? import sources.nixpkgs { },
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
  # Unused: could be used as base imaage
  alpine = dockerTools.pullImage {
    imageName = "alpine";
    imageDigest = "sha256:4edbd2beb5f78b1014028f4fbb99f3237d9561100b6881aabbf5acce2c4f9454"; # find this by instpecting the imageDigest of `docker pull alpine:3.15.4`
    sha256 = "L+Yxw4P2SlVJfgTgA3sjPcF0rgo3vijPg05czZ7xtYU="; # set to 0000..000 and then nix will tell you the sha when building the first time
    finalImageTag = "3.15.4";
    finalImageName = "alpine";
  };

  config = fromJSON (readFile ./config.json);
  hashF = import ./nix/hash-files.nix;
  basePath = ./. + config.baseConfig.path;
  userConfigPath = ./. + config.userConfig.path;
  validPath = x: lib.strings.hasSuffix ".nix" (toString x) && pathExists x;
  # make userConfig configuration optional
  existingUserConfig = (x: if (validPath x) then x else null) userConfigPath;
  imageName = hashF basePath;
  imageTag = hashF existingUserConfig;
  imageDest = "${config.env.DOCKER_REGISTRY_CONTAINER}/${imageName}:${imageTag}";

  containerImage = let
    config = {
      Cmd = [ "${bashInteractive}/bin/bash" ];
      WorkingDir = "/home/user";
    };
    minimalBase = dockerTools.buildImage {
      fromImage = null;
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

    contents = (import existingUserConfig { inherit pkgs; }).inputs;
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
      echo "Source is: $sourceURL"
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