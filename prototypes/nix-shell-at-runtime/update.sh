#!/bin/bash
nix-shell -p niv --run 'niv update nixpkgs'
nix-shell -p niv --run 'niv update nixpkgs-unstable'
