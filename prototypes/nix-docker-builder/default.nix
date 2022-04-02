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
  inherit containerImage;
  pushScript = writeScript "push-container-image-${imageTag}" ''
    #!${stdenv.shell}
    set -euo pipefail
    readonly imageUri="62r63d/${containerImage.imageName}:${containerImage.imageTag}"
    echo "Pushing $imageUri"
    exec "${skopeo}/bin/skopeo" copy \
    --quiet \
    --insecure-policy \
    --dest-creds "62r63d":"Jo1QGQbPYe5&w5" \
    "docker-archive:${containerImage}" \
    "docker://$imageUri"
  '';

  push = mkShell {
    shellHook = ''
      exec ${pushScript}
    '';
  };
}