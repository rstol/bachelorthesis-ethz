with (import <nixpkgs> { system = "x86_64-linux"; } );
let
  _python = pkgs.python39;
  pythonEnv = _python.withPackages (p: with p; [
    pandas
    numpy
    requests
    # other python packages in the minimal base image
  ]);
in
dockerTools.buildLayeredImage {
  name = "from-nixery-with-python";
  tag = "latest";

  fromImage = "nixery.dev/shell/git";

  contents = [
    (buildEnv {
      name = "env";
      paths = [
        pythonEnv
      ];
    })
  ];
  fakeRootCommands = ''
    mkdir -p ./home
    chown 1000 ./home
  '';
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
      # "/usr/bin/env nix-shell"
    ];
    WorkingDir = "/home";
  };
}