{ sources ? import nix/sources.nix }:
with builtins;
let
  # Unstable branch needed for cached-nix-shell
  pkgs = import sources.nixpkgs-unstable {
    overlays = [];
    config = { allowUnfree = false; };
  };
  inherit (pkgs.lib.strings)
    removePrefix
    ;
  inherit (pkgs)
    dockerTools
    stdenv
    bashInteractive
    skopeo
    runtimeShell
    writeScript
    runCommand
    cached-nix-shell
  ;

  userConfig = fromJSON (readFile ./config.json);
  configsRootDir = userConfig.configs.rootDir;
  baseConfigPath = ./. + (configsRootDir + "/" + userConfig.configs.baseFile);

  nixVersion = userConfig.env.NIX_VERSION;
  # The available versions are on: https://hub.docker.com/r/nixos/nix/tags
  nixFromDockerHub = dockerTools.pullImage {
    imageName = "nixos/nix";
    imageDigest = "sha256:fc55b9bf9f61742a3fc262c0dc9ad62ea8ace014bb5bd4b11341da879e7b26ce"; # find this by instpecting the imageDigest of `docker pull nixos/nix`
    sha256 = "1fy8da8zvwa8cbiyl4zbb1zmyz4hadcbw3klav0bzvd55rpg335f"; # set to 0000..000 and then nix will tell you the sha when building the first time
    finalImageTag = nixVersion;
    finalImageName = "nix";
    os = "linux";
  };

  configDir = userConfig.env.CONFIGDIR;
  scriptDir = userConfig.env.SCRIPTDIR;

  scriptsDirRel = removePrefix "/" scriptDir;
  configsDirRel = removePrefix "/" configDir;
  entryPoint = "home/runner/entrypoint.sh";
  containerImage = {
    name = envVars.IMAGE_NAME;
    tag = nixVersion;
    fromImage = nixFromDockerHub;

    # Nix already includes the following packages listed in: https://github.com/sajban/nix/blob/0cb81d070d657110c920578ce83f0eddd70d93a9/doc/manual/src/installation/installing-docker.md#what-is-included-in-nixs-docker-image
    # These packages don't need to be in the base config
    contents = [ cached-nix-shell ] ++ (import baseConfigPath { inherit pkgs; }).inputs;

    extraCommands = ''
    '';

    # Add files in the top layer to avoid having them in the Nix store
    fakeRootCommands = ''
      mkdir -p ${scriptsDirRel}
      cp -r ${./. + "/nix"}/* ${scriptsDirRel}
      chmod -R ugo=r ${scriptsDirRel}

      mkdir -p ${configsDirRel}
      cp -r ${./. + configsRootDir}/* ${configsDirRel}
      chmod -R ugo=r ${configsDirRel}

      cp ${./. + "/entrypoint.sh"} ${entryPoint}
      chmod u=rx,og=r ${entryPoint}
    '';

    maxLayers=110; # fromImage already has 101 layers
    config = {
      Cmd = [ "${bashInteractive}/bin/bash" ];
      Entrypoint = "/"+ entryPoint;
      Volumes = {
        "/nix" = {}; # cache the nix store
        "/root/.cache" = {}; # cache for the 'cached-nix-shell' tool stored at '~/.cache/cached-nix-shell/'
      };
      Env = [
        "CONFIGDIR=${configDir}"
        "SCRIPTDIR=${scriptDir}"
      ];
    };
  };
in {
  image = dockerTools.buildLayeredImage containerImage;

  push-streamed = runCommand "push-streamed-image-${containerImage.name}"
    {
      nativeBuildInputs = [ skopeo ];
      imageDest = "${envVars.DOCKER_REGISTRY_HOST}/${containerImage.name}:${containerImage.tag}";
    } ''
      #!${runtimeShell}
      set -eu
      echo "Pushing $imageDest"

      # remote Docker hub needs this option for auth: --dest-creds=<username>:<password> \
      ${dockerTools.streamLayeredImage containerImage} \
        | gzip --fast \
        | skopeo copy \
          --quiet \
          --insecure-policy \
          --dest-tls-verify=false \
          "docker-archive:/dev/stdin" \
          "docker://$imageDest"

      echo foo > $out
    '';
}