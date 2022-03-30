#!/bin/bash
mkdir -p out
nix-build $1
# if [ -h result/etc ]; then echo Error: Build resulted /etc as symlink && exit 1; fi
closurePath=$(nix-store -qR result)
cp $(nix-store -qR result) ./out
tarName=$(nix-store -qR result | sed -ne 's|^/nix/store/\(.*\)|\1|p')
ln -sf "out/"$tarName result