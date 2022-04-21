#!/bin/bash
# navigate to the directory containing this script
cd "$(dirname "$0")"

# set -euo pipefail

DATA_CONTAINER=nix-store-shell-repl
PROJECTROOT="$(dirname -- $(pwd -P))"
config="$PROJECTROOT/config.json"

DOCKER_REGISTRY_HOST="$(jq -r '.env.DOCKER_REGISTRY_HOST' "$config")"
NIXVERSION="$(jq -r '.env.NIX_VERSION' $config)"
IMAGE="$(jq -r '.env.BASE_IMAGE_NAME' $config)-$NIXVERSION"
WORKDIR="$(jq -r '.env.WORKDIR' $config)"
CONFIGDIR="$(jq -r '.env.CONFIGDIR' $config)"
SCRIPTDIR="$(jq -r '.env.SCRIPTDIR' $config)"
BASECONFIG="$(jq -r '.baseConfig.path | split("/") | .[-1]' $config)"
LOCALPATH="${WORKDIR}/$(jq -r '.localPath | split("/") | .[-1]' $config)"
PRESETPATH="${CONFIGDIR}/$(jq -r '.presetPath | split("/") | .[-1]' $config)"
