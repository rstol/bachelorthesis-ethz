#!/bin/bash
# navigate to the directory containing this script
PACKAGE=nix-builder
BUILDER_CONTAINER=nix-builder
DATA_CONTAINER=nix-store
BUILD_OPTIONS="--rm=true --force-rm=true --no-cache=true"
BUILDER_TAG=latest
PROJECTROOT="$(dirname -- $(pwd -P))"

# enable bash strict mode
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail

create() {
  if [[ -z $(docker images | grep $BUILDER_CONTAINER) ]]; then
    docker build -t $BUILDER_CONTAINER -f nix-builder.docker $BUILD_OPTIONS .
  else
    echo "builder container already exists."
  fi

  if [[ -z $(docker ps -a | grep $DATA_CONTAINER) ]]; then
    docker create --name $DATA_CONTAINER $BUILDER_CONTAINER
  else
    echo "data container already exists."
  fi
}

run() {
  if [[ -n $(docker images | grep $BUILDER_CONTAINER) ]]; then
    if [ "$#" -eq 0 ]; then
      # interactive mode
      docker run \
        -it \
        --rm \
        -v $PROJECTROOT:/home/user \
        --workdir="/home/user" \
        $BUILDER_CONTAINER
    else # run command
      docker run \
        --rm \
        -v $PROJECTROOT:/home/user \
        --workdir="/home/user" \
        $BUILDER_CONTAINER "$@"
    fi
  fi
}

if test $# -gt 0; then
  case "$1" in
    -h|--help)
      echo "$PACKAGE - attempt to create builder and data container for nix-builder"
      echo " "
      echo "Usage: $(basename $0) COMMAND"
      echo " "
      echo "Commands:"
      echo "  create           Create builder and data container if they don't exist already"
      echo "  run              Run builder container (use this i.e. for debugging the builder container)"
      echo "  prune-builder    Remove builder container"
      exit 0
      ;;
    create)
      create
      exit 0
      ;;
    run)
      run
      exit 0
      ;;
    prune-builder)
      docker rmi --force=true $BUILDER_CONTAINER
      exit 0
      ;;
    *)
      echo "script usage: $(basename $0) [COMMAND]"
      echo "Run '$(basename $0) --help' for more information on how to use the package.">&2
      exit 1
      ;;
  esac
else
  echo "script usage: $(basename $0) [COMMAND]" >&2
  echo "Run '$(basename $0) --help' for more information on how to use the package.">&2
  exit 1
fi



