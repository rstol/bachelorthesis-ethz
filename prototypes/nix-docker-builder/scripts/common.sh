
# navigate to the directory containing this script
cd "$(dirname "$0")"

PACKAGE=nix-builder
BUILDER_CONTAINER=nix-builder
DATA_CONTAINER=nix-store-builder
BUILD_OPTIONS="--rm=true --force-rm=true --no-cache=true"
BUILDER_TAG=latest
PROJECTROOT="$(dirname -- $(pwd -P))"
REGISTRY="localhost:5000"