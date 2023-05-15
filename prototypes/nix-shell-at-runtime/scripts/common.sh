#!/bin/bash
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

DATA_CONTAINER="NSAR-data-container"
PROJECTROOT="$(dirname -- "$(pwd -P)")"
config="$PROJECTROOT/config.json"

DOCKER_REGISTRY_HOST="$(jq -r '.env.DOCKER_REGISTRY_HOST' "$config")"
NIXVERSION="$(jq -r '.env.NIX_VERSION' $config)"
WORKDIR="$(jq -r '.env.WORKDIR' $config)"
CONFIGDIR="$(jq -r '.env.CONFIGDIR' $config)"
SCRIPTDIR="$(jq -r '.env.SCRIPTDIR' $config)"
BASEPATH="${CONFIGDIR}/$(jq -r '.configs.baseFile' $config)"
USERCONFIGPATH="${CONFIGDIR}/$(jq -r '.configs.userConfigFile' $config)"
get_image() {
    echo "$(jq -r '.env.IMAGE_NAME' "$config"):$NIXVERSION"
}