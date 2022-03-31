#!/bin/bash
BUILDER_CONTAINER=nix-builder
DATA_CONTAINER=nix-store
BUILD_OPTIONS="--rm=true --force-rm=true"
BUILDER_TAG=latest

if [[ -z $(docker images | grep $BUILDER_CONTAINER) ]]; then
  docker build -t $BUILDER_CONTAINER -f nix-builder.docker $BUILD_OPTIONS .
else
  echo "builder container already exists."
fi

if [[ -z $(docker ps -a | grep $DATA_CONTAINER) ]]; then
  docker create --name $DATA_CONTAINER $BUILDER_CONTAINER:$BUILDER_TAG
else
  echo "data container already exists."
fi


