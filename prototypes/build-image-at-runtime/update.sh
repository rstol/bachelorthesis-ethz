#!/bin/bash
nix-shell -p niv --run 'niv update nixpkgs -b release-21.11'
# nix-shell -p niv --run 'niv update nixpkgs-unstable -b nixos-unstable'
