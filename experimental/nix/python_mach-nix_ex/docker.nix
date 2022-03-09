with (import <nixpkgs> {});
dockerTools.buildLayeredImage {
    name = "python-env";
    contents = [ (import ./default.nix).paths ];
    config = {
      Cmd = [
        "/bin/python3"
      ];
    };
}
