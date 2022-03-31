#!/bin/bash
mkdir -p out
nix-build $1
# if [ -h result/etc ]; then echo Error: Build resulted /etc as symlink && exit 1; fi
if [ -L "result" ]; then
  tarName=$(nix-store -qR result | sed -ne 's|^/nix/store/\(.*\)|\1|p')

  if [ "$tarName" ]; then
    echo $tarName
  else
    exit 1
  fi
  if [ ! -f "out/$tarName" ]; then
    cp $(nix-store -qR result) ./out/
  fi
  if [ -f "out/$tarName" ]; then
    rm outlink
    ln -s "out/$tarName" outlink
  else
    echo "symlink could not be created, target does not exist"
  fi
fi