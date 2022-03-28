#!/bin/bash
nix-build $1
# if [ -h result/etc ]; then echo Error: Build resulted /etc as symlink && exit 1; fi
# nix-store -q result --graph | sed 's/#ff0000/#ffffff/' | dot -Nstyle=bold -Tpng > $1.png
mv $(nix-store -qR result) .