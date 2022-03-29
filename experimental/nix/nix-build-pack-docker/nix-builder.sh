#!/bin/bash
mkdir -p tmp
nix-build $1
# if [ -h result/etc ]; then echo Error: Build resulted /etc as symlink && exit 1; fi
# tarName=$(nix-store -qR result | sed -ne 's|^/nix/store/\(.*\)|\1|p')
out=$(nix-store -qR result)
# tar cvz --transform="s|^result/||" tmp #v = verbose, c = copy, z = zip, tranform directory that begins with result to "",
mv $out .