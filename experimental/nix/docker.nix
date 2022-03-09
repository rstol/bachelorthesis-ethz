{ localPkgs ? import <nixpkgs> {}
, imagePkgs ? import <nixpkgs> { system = "x86_64-linux"; }
}:

localPkgs.dockerTools.buildImage {
  name = "hello-docker";
  config = {
    Cmd = [ "${imagePkgs.hello}/bin/hello" ];
  };
}