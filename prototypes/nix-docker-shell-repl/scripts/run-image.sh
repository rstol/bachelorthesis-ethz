#!/bin/bash
source $(dirname "$0")/common.sh

create() {
  if [[ -z $(docker images -q $IMAGE) ]]; then
    if [ "$#" -eq 1 ] && [[ "$1" = "push" ]]; then
      docker load <$(nix-build $PROJECTROOT -A push-streamed --no-out-link)
    else
      docker load <$(nix-build $PROJECTROOT -A image --no-out-link)
    fi
  else
    echo "Image already exists."
  fi

  if [[ -z $(docker ps -a | grep $DATA_CONTAINER) ]]; then
    echo "Creating the data container..."
    docker create --name $DATA_CONTAINER $IMAGE
    # docker create --name $DATA_CONTAINER -v :/nix nixos/nix
  else
    echo "Persistent data container already exists."
  fi
}

run_image() {
  if [ "$#" -eq 0 ]; then
    # interactive mode
    docker run \
      -it \
      --rm \
      --volumes-from=$DATA_CONTAINER \
      -v $PROJECTROOT/env:$CONFIGDIR \
      -v $PROJECTROOT/workdir:$WORKDIR \
      --workdir=$WORKDIR \
      -e PRESETPATH=$PRESETPATH \
      -e LOCALPATH=$LOCALPATH \
      $IMAGE
  else # run command
    docker run \
      --rm \
      -it \
      --volumes-from=$DATA_CONTAINER \
      -v $PROJECTROOT/env:$CONFIGDIR \
      -v $PROJECTROOT/workdir:$WORKDIR \
      --workdir=$WORKDIR \
      -e PRESETPATH=$PRESETPATH \
      -e LOCALPATH=$LOCALPATH \
      $IMAGE "$@"
  fi
}

prune_image() {
  if [[ -n $(docker images -q "$IMAGE") ]]; then
    echo "Removing the image: $IMAGE..."
    docker rmi --force=true "$IMAGE"
  fi
}

prune_container() {
  if [[ -n $(docker ps -a | grep $DATA_CONTAINER) ]]; then
    echo "Removing the container and nix store cache..."
    docker container rm $DATA_CONTAINER --volumes
  fi
}

if test $# -gt 0; then
  case "$1" in
  -h | --help)
    echo "Approach 1 - create repl image with Nix installed and start nix-shell for user environment."
    echo " "
    echo "Usage: $(basename $0) COMMAND"
    echo " "
    echo "Commands:"
    echo "  create { push }               Create repl image and data container if they don't exist already. Push the image to the registry with the 'push' option."
    echo "  run { command }               Run builder container. Specify 'command' to run builder container interactively."
    echo "  prune { container | image }   Remove env image, store container and associated volume."
    echo "  purge-nix-cache               Clean up by purging the $DATA_CONTAINER cache"
    echo "  prebuild-store                Prebuild the nix store based on the configurations ('baseConfig.path' and 'presetPath') specified in config.json."
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
    shift
    run_image "$@"
    exit 0
    ;;
  prune)
    shift
    if test $# -gt 0; then
      if [[ $1 == "container" ]]; then
        prune_container
      elif [[ $1 == "image" ]]; then
        prune_image
      fi
      shift
    else
      # remove all
      prune_image
      prune_container
    fi
    exit 0
    ;;
  purge-nix-cache)
    shift
    docker run --rm --volumes-from=$DATA_CONTAINER $IMAGE nix-collect-garbage -d
    exit 0
    ;;
  prebuild-store)
    shift
    run_image nix-env -f "$CONFIGDIR/$BASECONFIG" -iA inputs
    run_image nix-env -f "$PRESETPATH" -iA inputs
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
