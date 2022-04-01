#!/bin/sh

set -eu

# $(nix-build --no-out-link $1) | gzip --fast | skopeo --insecure-policy copy docker-archive:/dev/stdin docker://localhost:5000/python39-extended:latest
nix-build $1

# OCI_ARCHIVE=$(nix-build --no-out-link $1)


mkdir -p out
if [ -L "result" ]; then
  tarName=$(nix-store -qR result | sed -ne 's|^/nix/store/\(.*\)|\1|p')

  if [ ! -f "out/$tarName" ]; then
    cp $(nix-store -qR result) ./out/
  fi
  if [ -f "out/$tarName" ]; then
    ln -sf "out/$tarName" outlink
  else
    echo "symlink could not be created, target does not exist"
  fi
fi