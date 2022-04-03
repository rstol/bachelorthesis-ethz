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
  IMAGE="$(md5 -q -s "$hash")"
else
  # compute hash for each file and concatetenate resulting hash strings
  for f in "${sorted[@]}"
  do
    md5=($(md5sum "$f"))
    hash+="$md5"
  done
  # hash of concatenated hashes
  IMAGE=($(echo -n "$hash" | md5sum))
fi
echo "$IMAGE"