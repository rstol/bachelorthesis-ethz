#!/bin/sh
cd "$(dirname "$0")"
PROJECTROOT="$(dirname -- $(pwd -P))"

files=()
for file in ${PROJECTROOT}/nix/*
do
  if [[ -f $file ]]; then
    files+=($file)
  fi
done

# cmd=${@:-"${PROJECTROOT}/nix/local.nix ${PROJECTROOT}/nix/python.nix ${PROJECTROOT}/nix/minimal-base.nix"}
# files=($cmd)

#sort array first to make hash deterministic
IFS=$'\n' sorted=($(sort <<<"${files[*]}")); unset IFS

if [[ "$OSTYPE" == "darwin"* ]]; then
  # compute hash for each file and concatetenate resulting hash strings
  for f in "${sorted[@]}"
  do
    md5=($(md5 -r "$f"))
    hash+="$md5"
  done
  # hash of concatenated hashes
  res_hash=$(md5 -q -s "$hash")
else
  # compute hash for each file and concatetenate resulting hash strings
  for f in "${sorted[@]}"
  do
    md5=($(md5sum "$f"))
    hash+="$md5"
  done
  # hash of concatenated hashes
  res_hash=($(echo -n "$hash" | md5sum))
fi
echo "$res_hash"