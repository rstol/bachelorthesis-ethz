#!/bin/bash
# ./run-image.sh -r

BUILDER_CONTAINER=nix-builder
DATA_CONTAINER=nix-store
BUILDER_TAG=latest
PROJECTROOT="$(pwd -P)"
IMAGE=

# build repl env image tarball
build_image_tar() {
  if [[ -n $(docker images | grep $BUILDER_CONTAINER) ]] && [[ -n $(docker ps -a | grep $DATA_CONTAINER) ]]; then
    local val=${@:-"nix-builder.sh docker.nix"}
    docker run \
      --rm \
      --volumes-from=$DATA_CONTAINER \
      -v $PROJECTROOT:/home/user \
      --workdir="/home/user" \
      $BUILDER_CONTAINER:$BUILDER_TAG \
      bash -c "$@"
  else
    echo "Builder container or data container not found. Try building them first."
    exit 1
  fi
}

# load into docker
load_tar() {
  if [ -L "outlink" ]; then
    IMAGE="$(docker load < outlink | sed -ne 's|^Loaded image:\([a-zA-Z0-9]*\)|\1|p')"
    echo "Image name is $IMAGE"
  else
    echo "symlink to the image tarball does not exist"
    exit 1
  fi
}

# start image and run command
run_image() {
  if [ -z $IMAGE ]; then load_tar; fi
  if [[ -n $(docker images $IMAGE) ]]; then
    if [ "$#" -eq 0 ]; then
      # interactive mode
      docker run \
        --rm \
        -v $PROJECTROOT/workdir:/home/user \
        --workdir="/home/user" \
        $IMAGE
    else # run command
      docker run \
        --rm \
        -v $PROJECTROOT/workdir:/home/user \
        --workdir="/home/user" \
        $IMAGE "$@"
    fi
  else
    echo "Image is not available locally. Try building it first."
    exit 1
  fi
}

while getopts ':blr:' OPTION; do
  case "$OPTION" in
    b)
      echo "building the image in a builder container"
      build_image_tar "$OPTARG"
      load_tar
      ;;
    l)
      echo "load tar into docker"
      load_tar
      ;;
    r)
      # TODO: change this to allow image name specification as: image=<>
      avalue="$OPTARG"
      run_image $avalue
      ;;
    ?)
      echo "script usage: $(basename \$0) [-b] [-l] [-r command to execute in user container]" >&2
      exit 1
      ;;
  esac
done
shift "$(($OPTIND -1))"

