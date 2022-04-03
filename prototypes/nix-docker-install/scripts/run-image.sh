#!/bin/bash
# navigate to the directory containing this script
cd "$(dirname "$0")"
PROJECTROOT="$(dirname -- $(pwd -P))"
DATA_CONTAINER=nix-store-a1

IMAGE=$(./hash-files.sh)
if [[ -z $(docker images -q $IMAGE) ]]; then
  docker load < $(nix-build $PROJECTROOT --no-out-link)
else
  echo "builder container already exists."
fi
if [[ -z $(docker ps -a | grep $DATA_CONTAINER) ]]; then
  echo "creating data container: $DATA_CONTAINER"
  docker create --name $DATA_CONTAINER $IMAGE
else
  echo "data container already exists."
fi

echo "run image: $IMAGE"
docker run \
  -it \
  --rm \
  --volumes-from=$DATA_CONTAINER \
  -v $PROJECTROOT/workdir:/home/user \
  --workdir="/home/user" \
  $IMAGE \
  $@