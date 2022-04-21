#!/bin/bash
source $(dirname "$0")/common.sh

create() {
  if [[ -z $(docker images -q $BUILDER_CONTAINER) ]] || ([ "$#" -eq 1 ] && [[ "$1" = "-f" ]]); then
    echo "Creating the builder image..."
    docker load <$(nix-build "$PROJECTROOT/builder/" -A image --no-out-link)
    echo "Done"
  else
    echo "builder container already exists."
  fi

  if [[ -z $(docker ps -a | grep $DATA_CONTAINER) ]]; then
    echo "Creating the data container..."
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
        --volumes-from=$DATA_CONTAINER \
        $BUILDER_CONTAINER
    else # run command
      docker run \
        --rm \
        -v $PROJECTROOT:/home/user \
        --volumes-from=$DATA_CONTAINER \
        --workdir="/home/user" \
        $BUILDER_CONTAINER "$@"
    fi
  fi
}

prune_image() {
  if [[ -n $(docker images -q $BUILDER_CONTAINER) ]]; then
    echo "Removing the builder image..."
    docker rmi --force=true $BUILDER_CONTAINER
  fi
}

prune_store() {
  if [[ -n $(docker ps -a | grep $DATA_CONTAINER) ]]; then
    echo "Removing the builder container and nix store cache..."
    docker container rm $DATA_CONTAINER --volumes
  fi
}

prune() {
  if test $# -gt 0; then
    if [[ $1 == "builder" ]]; then
      prune_image
    elif [[ $1 == "store" ]]; then
      prune_store
    fi
  else
    # remove all
    prune_image
    prune_store
  fi
}

if test $# -gt 0; then
  case "$1" in
  -h | --help)
    echo "Nix-builder - attempt to create builder and data container for nix-builder"
    echo " "
    echo "Usage: $(basename $0) COMMAND"
    echo " "
    echo "Commands:"
    echo "  create {-i }                  Create builder and data container if they don't exist already. option '-f' to build a new image even if image already exists."
    echo "  run { command }               Run builder container. Specify 'command' to run builder container interactively."
    echo "  prune { builder | store }     Remove builder image, store container and associated volume."
    echo "  purge-nix-cache               Clean up by purging the $DATA_CONTAINER cache"
    exit 0
    ;;
  create)
    shift
    if test $# -gt 0; then
      create $1
    else
      create
    fi
    exit 0
    ;;
  run)
    run
    exit 0
    ;;
  prune)
    shift
    prune $@
    exit 0
    ;;
  purge-nix-cache)
    shift
    docker run --rm --volumes-from=$DATA_CONTAINER $BUILDER_CONTAINER nix-collect-garbage -d
    exit 0
    ;;
  *)
    echo "script usage: $(basename $0) [COMMAND]"
    echo "Run '$(basename $0) --help' for more information on how to use the package." >&2
    exit 1
    ;;
  esac
else
  echo "script usage: $(basename $0) [COMMAND]" >&2
  echo "Run '$(basename $0) --help' for more information on how to use the package." >&2
  exit 1
fi
