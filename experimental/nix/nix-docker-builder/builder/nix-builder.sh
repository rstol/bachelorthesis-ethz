#!/bin/sh

set -eu

# $(nix-build --no-out-link $1) | gzip --fast | skopeo --insecure-policy copy docker-archive:/dev/stdin docker://localhost:5000/python39-extended:latest
nix-build $1

OCI_ARCHIVE=$(nix-build --no-out-link $1)