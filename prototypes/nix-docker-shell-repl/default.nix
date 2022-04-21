{ pkgs ? import <nixpkgs> { system = "x86_64-linux"; } }:
with builtins;
let
  lib = import <nixpkgs/lib>;
  inherit (pkgs)
    writeShellApplication
    dockerTools
    stdenv
    bashInteractive
    skopeo
    writeText
    runtimeShell
    writeScript
    runCommand
    writeShellScriptBin
    buildEnv
  ;

  userConfig = fromJSON (readFile ./config.json);
  baseConfigPath = ./. + userConfig.baseConfig.path;

  nixVersion = userConfig.env.NIX_VERSION;
  # Nix already includes the following packages listed in: https://github.com/sajban/nix/blob/0cb81d070d657110c920578ce83f0eddd70d93a9/doc/manual/src/installation/installing-docker.md#what-is-included-in-nixs-docker-image
  nixFromDockerHub = dockerTools.pullImage {
    imageName = "nixos/nix";
    imageDigest = "sha256:fc55b9bf9f61742a3fc262c0dc9ad62ea8ace014bb5bd4b11341da879e7b26ce"; # find this by instpecting the imageDigest of `docker pull nixos/nix`
    sha256 = "1fy8da8zvwa8cbiyl4zbb1zmyz4hadcbw3klav0bzvd55rpg335f"; # set to 0000..000 and then nix will tell you the sha when building the first time
    finalImageTag = nixVersion;
    finalImageName = "nix";
    os = "linux";
  };

  uid = "602";
  gid = "602";
  user = "cxuser";
  group = "601";
  home = "/var/lib/cxuser";
  rootUser = "cxrun:cxrun";
  workdir = userConfig.env.WORKDIR;
  configDir = userConfig.env.CONFIGDIR;
  scriptDir = userConfig.env.SCRIPTDIR;

  initNixProxy = runCommand "init-nix-proxy" {} ''
    mkdir -p $out/opt
    cd $out/opt/
    cp ${./. + userConfig.nixProxyPath} nixproxy.nix
  '';

  entrypoint = writeScript "entrypoint.sh" ''
    #!${stdenv.shell}
    set -e

    # declare -xp

    if test $# -gt 0; then
      if [ "$1" = 'cached-nix-shell-cmd' ]; then
        shift
        exec cached-nix-shell /opt/nixproxy.nix --argstr localPath $LOCALPATH --argstr presetPath $PRESETPATH --command "$@"
      elif  [ "$1" = 'cached-nix-shell' ]; then
        exec cached-nix-shell /opt/nixproxy.nix --argstr localPath $LOCALPATH --argstr presetPath $PRESETPATH
      elif [ "$1" = 'nix-shell-cmd' ]; then
        shift
        exec nix-shell /opt/nixproxy.nix --argstr localPath $LOCALPATH --argstr presetPath $PRESETPATH --command "$@"
      elif [ "$1" = 'nix-shell' ]; then
        exec nix-shell /opt/nixproxy.nix --argstr localPath $LOCALPATH --argstr presetPath $PRESETPATH
      fi
    fi

    exec "$@"
  '';

  # linux with kvm is required to run this command
  runAsRoot = ''
    #!${stdenv.shell}
    set -e
    ${dockerTools.shadowSetup}
    # cxuser:cxuser (602:602) unpriviledged user
    groupadd -gid "${gid}" \
            --system "${user}
    useradd --uid "${uid}" \
            --gid "${gid}" \
            # add to cxrun group 601
            --groups "${group}" \
            --home-dir "${home}" \
            --create-home \
            --comment 'unprivideged cxenv user' \
            --shell /sbin/nologin \
            --system "${user}"
  '';

  containerImage = let
    nixRoot = dockerTools.buildImage {
      fromImage = nixFromDockerHub;
      name = "nix-root";
      tag = "latest";

      contents = (import baseConfigPath { inherit pkgs; }).inputs;
      # inherit runAsRoot;
    };
  in {
    name = userConfig.env.BASE_IMAGE_NAME + "-" + nixVersion;
    tag = "latest";
    fromImage = nixRoot;

    contents = [
      (buildEnv {
        name = "init";
        paths = [
          initNixProxy
         ];
      })
    ];

    extraCommands = ''
    '';

    maxLayers=120; # fromImage already has 102 layers
    config = {
      Cmd = [ "${bashInteractive}/bin/bash" ];
      Entrypoint = [ entrypoint ];
      Volumes = {
        "/nix" = {}; # cache the nix store
        "/root/.cache" = {}; # cache for the 'cached-nix-shell' command
      };
      Env = [
        "USER=${rootUser}"
        "WORKDIR=${workdir}"
        "CONFIGDIR=${configDir}"
        "PATH=${lib.concatStringsSep ":" [
          "/bin"
          "/root/.nix-profile/bin"
          "/nix/var/nix/profiles/default/bin"
          "/nix/var/nix/profiles/default/sbin"
        ]}"
      ];
    };
  };
in {
  image = dockerTools.buildLayeredImage containerImage;

  push-streamed = runCommand "push-streamed-image-${containerImage.name}"
    {
      nativeBuildInputs = [ skopeo ];
      imageDest = "${userConfig.env.DOCKER_REGISTRY_HOST}/${containerImage.name}:${containerImage.tag}";
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