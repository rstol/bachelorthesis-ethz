#!/bin/bash
source $(dirname "$0")/common.sh

# build repl env image
build_image() {
  # IMAGE=$(./hash-files.sh)
  # if [[ -n $(docker images -q $IMAGE) ]]; then
  #   echo "The image is already available locally"
  #   exit 0
  # fi
  if [[ -n $(docker images -q $BUILDER_CONTAINER) ]] && [[ -n $(docker ps -a | grep $DATA_CONTAINER) ]]; then
    if test $# -gt 0 && [[ "$1" == "-i" ]]; then
      # interactive mode
      docker run \
        -it \
        --rm \
        --volumes-from=$DATA_CONTAINER \
        -v $PROJECTROOT:/home/user \
        --workdir="/home/user" \
        $BUILDER_CONTAINER
    else # run command
      cmd=${@:-"streamed"}
      docker run \
        --rm \
        --volumes-from=$DATA_CONTAINER \
        -v $PROJECTROOT:/home/user \
        --workdir="/home/user" \
        $BUILDER_CONTAINER \
        $cmd
    fi
  else
    echo "Builder container or data container not found. Try building them first."
    exit 1
  fi
}

pull_from_registry() {
  get_image
  docker pull $ENV_IMAGE
}

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
      -v $PROJECTROOT/workdir/user:/home/user \
      --workdir="/home/user" \
      "$ENV_IMAGE"
  else # run command
    docker run \
      --rm \
      --net none \
      -v $PROJECTROOT/workdir/user:/home/user \
      --workdir="/home/user" \
      "$ENV_IMAGE" \
      $@
  fi
}

while test $# -gt 0; do
  case "$1" in
  -h | --help)
    echo "Env-image - build an environment image, push it to the registry, pull it and run it on the local host."
    echo " "
    echo "Usage: $(basename $0) COMMAND"
    echo " "
    echo "Commands:"
    echo "  build { -i | command}     Build repl image using the builder container and push it to the registry.
                              optional:
                                specify 'command' as an arbitrary build command or as one of the following values:
                                  'streamed': to build and push a streamed image to the registry
                                  'layered': to build and push a layered image to the registry
                                  'sh': start shell
                                flag '-i' to run interactive"
    echo "  run {command}             Run image and start container.
                              optional: specify 'command' to run in the container non-interactive.
                                        specify flag '-i' to run interactive"
    echo "  pull                      Pull image from the registry."
    echo "  prune                     Remove repl env image"
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
  prune)
    get_image
    if [[ -n $(docker images -q "$ENV_IMAGE") ]]; then
      docker rmi --force=true "$ENV_IMAGE"
    fi
    exit 0
    ;;
  *)
    echo "Run '$(basename $0) --help' for more information on how to use the package." >&2
    break
    ;;
  esac
done
