#!/bin/bash
source $(dirname "$0")/common.sh

tagHash="latest"
baseFile="$PROJECTROOT$(jq -cr '.baseConfig.path' $config)"
if [[ "$OSTYPE" == "darwin"* ]]; then
  #sort array to make hash deterministic
  tagHash=$(jq -cr '.userConfig | map(select(.path | contains(".nix")).path) | sort | .[]' $config |
    while read -r file; do cat "$PROJECTROOT$file" | md5; done |
    jq -scr -R 'split("\n") | add')
  nameHash=$(cat "$baseFile" | md5)
  echo "$nameHash:$(md5 -q -s $tagHash)"
else
  #sort array to make hash deterministic
  tagHash=$(jq -cr '.userConfig | map(select(.path | contains(".nix"))) | sort | .[]' $config |
    while read -r file; do cat "$PROJECTROOT$file" | md5sum | cut -d' ' -f1; done |
    jq -scr -R 'split("\n") | add')
  tagHash=($(echo -n "$tagHash" | md5sum))
  nameHash=$(cat "$baseFile" | md5sum | cut -d' ' -f1)
  echo "$nameHash:$tagHash"
fi

# Remark: This implementation of hashing the files to get the image name and tag produces the same output as the hash-files.nix implementation.
