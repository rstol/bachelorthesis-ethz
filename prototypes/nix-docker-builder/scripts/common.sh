# navigate to the directory containing this script
cd "$(dirname "$0")"

set -euo pipefail

BUILDER_CONTAINER=nix-builder
DATA_CONTAINER=nix-store-builder
BUILDER_TAG=latest
PROJECTROOT="$(dirname -- $(pwd -P))"
config="$PROJECTROOT/config.json"
DOCKER_REGISTRY_HOST=""
if [ -z $DOCKER_REGISTRY_HOST ]; then
  DOCKER_REGISTRY_HOST="$(jq -r '.env.DOCKER_REGISTRY_HOST' "$config")" # default registry
fi
ENV_IMAGE=""
get_image() {
  if [ -z "$ENV_IMAGE" ]; then
    ENV_IMAGE="$DOCKER_REGISTRY_HOST/$(./hash-files.sh)"
  fi
}
