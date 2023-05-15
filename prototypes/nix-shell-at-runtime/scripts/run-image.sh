#!/bin/bash
#
# Author: Romeo Stoll <stollr@student.ethz.ch>
#
# shellcheck source=./common.sh
source "$(dirname "$0")/common.sh"
IMAGE=$(get_image)

create() {
    if [[ -z $(docker images -q "$IMAGE") ]]; then
        if [ "$#" -eq 1 ] && [[ "$1" = "push" ]]; then
            log "Building and pushing image: $IMAGE"
            docker load <"$(nix-build $PROJECTROOT -A push-streamed --no-out-link)"
        else
            log "Building image: $IMAGE"
            docker load <"$(nix-build $PROJECTROOT -A image --no-out-link)"
            # docker build -t "$IMAGE" $PROJECTROOT
        fi
    else
        log "Image already exists."
    fi

    if [[ -z $(docker ps -a | grep "$DATA_CONTAINER") ]]; then
        log "Creating data container with persistent volumes..."
        docker create --name "$DATA_CONTAINER" "$IMAGE"
    else
        log "Container which initializes persistent data volume already exists."
    fi
}

run_image() {
  if [ "$#" -eq 0 ]; then
    # interactive mode
    docker run \
      -it \
      --rm \
      --volumes-from=$DATA_CONTAINER \
      -v $PROJECTROOT/workdir/user:$WORKDIR:rw \
      -w $WORKDIR \
      -e USERCONFIGPATH=$USERCONFIGPATH \
      $IMAGE
  else # run command
    docker run \
      --rm \
      -it \
      --volumes-from=$DATA_CONTAINER \
      -v $PROJECTROOT/workdir/user:$WORKDIR:rw \
      -w $WORKDIR \
      -e USERCONFIGPATH=$USERCONFIGPATH \
      $IMAGE "$@"
  fi
}

prune_image() {
    if [[ -n $(docker images -q "$IMAGE") ]]; then
        log "Removing the image: $IMAGE..."
        docker rmi --force=true "$IMAGE"
    else
        log "Image does not exist"
    fi
}

prune_container() {
    if [[ -n $(docker ps -a | grep "$DATA_CONTAINER") ]]; then
        log "Removing the container and nix store cache..."
        docker container rm "$DATA_CONTAINER" --volumes
    else
        log "Data container does not exist"
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
    if test $# -eq 1; then
      if [[ $1 == "push" ]]; then
        create $1
        shift
      fi
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
    if test $# -eq 1; then
      if [[ $1 == "container" ]]; then
        prune_container
        shift
      elif [[ $1 == "image" ]]; then
        prune_image
        shift
      fi
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
  create-and-prebuild)
    shift
    create
    log "Prebuilding the store..."
    run_image nix-env -f "$SCRIPTDIR/nixproxy.nix" -i -E "f: (f { userConfigPath = $USERCONFIGPATH; })"
    ;;
  prebuild-store)
    shift
    log "Prebuilding the store..."
    run_image nix-env -f "$SCRIPTDIR/nixproxy.nix" -i -E "f: (f { userConfigPath = $USERCONFIGPATH; })"
    exit 0
    ;;
  *)
    echo "script usage: $(basename $0) [COMMAND]"
    echo "Run '$(basename $0) --help' for more information on how to use the package." >&2
    exit 1
fi
