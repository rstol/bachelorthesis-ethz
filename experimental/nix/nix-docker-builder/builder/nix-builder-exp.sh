#!/bin/sh

set -eu

nix-build -A deploy-script --no-out-link $1
# | gzip --fast | skopeo --insecure-policy copy docker-archive:/dev/stdin docker://localhost:5000/python39s-extended:latest
# OCI_ARCHIVE=$(nix-build --no-out-link $1)
