{
  type ? "develop",
  sourcesFile ? "/nix/sources.nix",
}:
let
  nixpkgs = (import (./. + sourcesFile)).nixpkgs;
  pkgs = import nixpkgs {
    overlays = [];
    config = { allowUnfree = false; };
  };
  inherit (pkgs) lib;

  dependencies = let mapping = {
    develop = developDeps ++ testDeps ++ buildDeps;
    test = testDeps ++ buildDeps ++ runDeps;
    build = buildDeps ++ runDeps;
    run = runDeps;
  }; in mapping.${type} or (throw
    "${type} is not a valid shell type. Valid ones are ${toString (lib.attrNames mapping)}");

  stdenv = if type == "develop" then pkgs.stdenv else pkgs.stdenvNoCC;

  pythonEnv = with pkgs; python39.withPackages(x: with x; [ pandas matplotlib ]);
  developDeps = with pkgs; [
    vim
    curl
    jq

    pythonEnv
  ];

  # These are needed to run tests in CI/CD
  testDeps = with pkgs; [];

  # These are needed to build the repl
  buildDeps = with pkgs; [
  ];

  # Only these dependencies are needed during the repl runtime
  runDeps = with pkgs; [
    cached-nix-shell
  ];
in

stdenv.mkDerivation {
  name = "dev-shell";
  buildInputs = dependencies;

  # Such that nixpkgs doesn't need to be downloaded again when running we make
  # it a dependency of the derivation. Also allows using `nix-shell -p` with the
  # correct nixpkgs version
  NIX_PATH = "nixpkgs=${nixpkgs}";
}