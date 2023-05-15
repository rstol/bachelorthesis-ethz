#! /usr/bin/env nix-shell
#! nix-shell -p bench jq
#
# Author: Romeo Stoll <stollr@student.ethz.ch>
#

# navigate to the directory containing this script
cd "$(dirname "$0")"

set -o errexit  # abort on nonzero exitstatus
set -o nounset  # abort on unbound variable
set -o pipefail # don't hide errors within pipes

readonly yellow='\e[0;33m'
readonly reset='\e[0m'

# Usage: log [ARG]...
#
# Prints all arguments on the standard output stream
log() {
  printf "${yellow}>> %s${reset}\n" "${*}"
}

BUILDER_CONTAINER=nix-builder
DATA_CONTAINER=BIAR-data-container
BUILDER_TAG=latest
PROJECTROOT="$(dirname -- $(pwd -P))"
config="$PROJECTROOT/config.json"
DOCKER_REGISTRY_HOST=""
DOCKER_REGISTRY_HOST="$(jq -r '.env.DOCKER_REGISTRY_HOST' "$config")"
ENV_IMAGE=""
get_image() {
  ENV_IMAGE="$DOCKER_REGISTRY_HOST/$(./hash-files.sh)"
}
