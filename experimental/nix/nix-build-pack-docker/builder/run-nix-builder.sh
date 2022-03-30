#!/bin/bash
BUILDER_CONTAINER=nix-builder
DATA_CONTAINER=nix-store
BUILD_OPTIONS="--rm=true --force-rm=true --no-cache=true"

if [[ docker ps -a | grep $(DATA_CONTAINER) ]]; then
  docker create --name $(DATA_CONTAINER) $(BUILDER_CONTAINER)
fi



