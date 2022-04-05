#!/bin/bash
# navigate to the directory containing this script
cd "$(dirname "$0")"

BUILDER_CONTAINER=nix-builder
DATA_CONTAINER=nix-store-builder
BUILDER_TAG=latest
PROJECTROOT="$(dirname -- $(pwd -P))"
REGISTRY="localhost:5000"
ENV_IMAGE=""
# build repl env image
build_image() {
  # IMAGE=$(./hash-files.sh)
  # if [[ -n $(docker images -q $IMAGE) ]]; then
  #   echo "The image is already available locally"
  #   exit 0
  # fi
  if [[ -n $(docker images -q $BUILDER_CONTAINER) ]] && [[ -n $(docker ps -a | grep $DATA_CONTAINER) ]]; then
    if [ "$1" == "-i" ]; then
      shift
      # interactive mode
      docker run \
        -it \
        --rm \
        --network=host \
        --volumes-from=$DATA_CONTAINER \
        -v $PROJECTROOT:/home/user \
        --workdir="/home/user" \
        $BUILDER_CONTAINER \
        $@
    else # run command
      docker run \
        --rm \
        --network=host \
        --volumes-from=$DATA_CONTAINER \
        -v $PROJECTROOT:/home/user \
        --workdir="/home/user" \
        $BUILDER_CONTAINER \
        $@
    fi
  else
    echo "Builder container or data container not found. Try building them first."
    exit 1
  fi
}

get_image() {
  if [ -z "$ENV_IMAGE" ]; then
    ENV_IMAGE="$REGISTRY/$(./hash-files.sh)"
  fi
}

pull_from_registry() {
  get_image
  docker pull $ENV_IMAGE
}
# docker run -it --rm --log-driver=none -a stdin -a stdout -a stderr --volumes-from=nix-store -v $(pwd):/home/user nix-builder bash $(nix-build --no-out-link docker.nix) | docker load

# start image and run command
run_image() {
  get_image
  echo "Running image: '$ENV_IMAGE'"
  if [ "$#" -eq 0 ]; then
    # interactive mode
    docker run \
      -it \
      --rm \
      --net none \
      -v $PROJECTROOT/workdir:/home/user \
      --workdir="/home/user" \
      $ENV_IMAGE
  else # run command
    docker run \
      --rm \
      --net none \
      -v $PROJECTROOT/workdir:/home/user \
      --workdir="/home/user" \
      $ENV_IMAGE \
      $@
  fi
}

while test $# -gt 0; do
  case "$1" in
    -h|--help)
      echo "$PACKAGE - attempt to create builder and data container for nix-builder"
      echo " "
      echo "Usage: $(basename $0) COMMAND"
      echo " "
      echo "Commands:"
      echo "  build            Build repl image using the builder container.  (optional: specify command to build the repl image). Use flag '-i' to run container interactive"
      echo "  run              Run image and start container with bash in interactive mode. (optional: specify command to run image non-interactive)"
      echo "  prune-repl       Remove repl image container"
      exit 0
      ;;
    build)
      shift
      build_image $@
      exit 0
      ;;
    pull)
      shift
      pull_from_registry
      ;;
    run)
      shift
      run_image $@
      exit 0
      ;;
    prune-repl)
      docker rmi --force=true $(./hash-files.sh)
      exit 0
      ;;
    *)
      echo "Run '$(basename $0) --help' for more information on how to use the package.">&2
      break
      ;;
  esac
done