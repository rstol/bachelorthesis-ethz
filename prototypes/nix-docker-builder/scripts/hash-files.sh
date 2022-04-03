#!/bin/sh
cd "$(dirname "$0")"
PROJECTROOT="$(dirname -- $(pwd -P))"

configs=()
for file in ${PROJECTROOT}/env/*
do
  if [[ -f $file ]]; then
    nixConfigs+=($file)
  fi
done

# cmd=${@:-"${PROJECTROOT}/env/local.nix ${PROJECTROOT}/env/python.nix ${PROJECTROOT}/env/minimal-base.nix"}
# nixConfigs=($cmd)
localConfig=${PROJECTROOT}/workdir/local.nix

#sort array first to make hash deterministic
IFS=$'\n' sorted=($(sort <<<"${nixConfigs[*]}")); unset IFS

if [[ "$OSTYPE" == "darwin"* ]]; then
  # compute hash for each file and concatetenate resulting hash strings
  for f in "${sorted[@]}"
  do
    md5=($(md5 -r "$f"))
    hash+="$md5"
  done
  # hash of concatenated hashes
  IMAGE="$(md5 -q -s "$hash"):$(md5 -q "$localConfig")"
else
  # compute hash for each file and concatetenate resulting hash strings
  for f in "${sorted[@]}"
  do
    md5=($(md5sum "$f"))
    hash+="$md5"
  done
  # hash of concatenated hashes
  IMAGE=($(echo -n "$hash" | md5sum))
  TAG=($(md5sum "$localConfig"))
  IMAGE="$IMAGE:$TAG"
fi
echo "$IMAGE"