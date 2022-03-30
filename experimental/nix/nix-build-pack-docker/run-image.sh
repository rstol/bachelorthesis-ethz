# build repl env image tarball
docker run -it --rm --volumes-from=nix-store -v $(pwd):/home/user nix-builder:latest bash nix-builder.sh docker.nix
# load into docker
imageName=$(docker load < result | sed -ne 's|^Loaded image:\([a-zA-Z0-9^\s]*\)|\1|p')
# start image and run command
docker run --rm -v $(pwd)/workdir:/home/user $imageName $1 $2