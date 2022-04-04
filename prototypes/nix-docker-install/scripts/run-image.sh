#!/bin/bash
# navigate to the directory containing this script
cd "$(dirname "$0")"
PROJECTROOT="$(dirname -- $(pwd -P))"
DATA_CONTAINER=nix-store-env

IMAGE=$(./hash-files.sh)
echo "run image: $IMAGE"
docker run \
  -it \
  --rm \
  --volumes-from=$DATA_CONTAINER \
  -v $PROJECTROOT/workdir:/home/user \
  --workdir="/home/user" \
  $IMAGE \
  $@