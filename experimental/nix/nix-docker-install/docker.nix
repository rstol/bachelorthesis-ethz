with (import <nixpkgs> { system = "x86_64-linux"; } );
let
  debianFromDockerHub = dockerTools.pullImage {
    imageName = "debian";
    imageDigest = "sha256:4ceca80e912f5fd88749d9984597fbe81d436049745b07b54cd2b112ea3a4618";
    sha256 = "9c4db2a9644ee3029a8e9cca58350efef660c3167e59b91f2bee9c303e592664";
    finalImageName = "debian";
  };
  nixFromDockerHub = dockerTools.pullImage {
    imageName = "nixos/nix";
    imageDigest = "sha256:85299d86263a3059cf19f419f9d286cc9f06d3c13146a8ebbb21b3437f598357";
    sha256 = "19fw0n3wmddahzr20mhdqv6jkjn1kanh6n2mrr08ai53dr8ph5n7";
    finalImageTag = "2.2.1";
    finalImageName = "nix";
  };
  _python = pkgs.python39;
  pythonEnv = _python.withPackages (p: with p; [
    pandas
    numpy
    requests
    # other python packages in the minimal base image
  ]);
  # symlink = pkgs.runCommand "copy" {} "ln -s ${target} $out";
in
dockerTools.buildLayeredImage {
  name = "nix-with-python";
  tag = "latest";

  fromImage = ./nix-base.tar;

  contents = [
    # pkgs.runCommand "channel-nixos" { } ''
    #     mkdir $out
    #     ln -s ${nixpkgs} $out/nixpkgs
    #     echo "[]" > $out/manifest.nix
    #   ''
    (buildEnv {
      name = "env";
      paths = [
        coreutils
        bash
        vim
        # other core packages

        pythonEnv
      ];
    })
  ];
  # fakeRootCommands = ''
  #   mkdir -p ./home
  #   chown 1000 ./home
  #   cp -p ./shell.nix ./home
  #   cp -p ./user_defined.nix ./home
  # '';
  config = {
    Env = [
      # nix-store uses cat program to display results as specified by
      # the image env variable NIX_PAGER.
      "NIX_PAGER=cat"
      # A user is required by nix
      # https://github.com/NixOS/nix/blob/9348f9291e5d9e4ba3c4347ea1b235640f54fd79/src/libutil/util.cc#L478
      "USER=user"
    ];
    Cmd = [
      "/bin/sh"
    ];
    WorkingDir = "/home";
  };
}