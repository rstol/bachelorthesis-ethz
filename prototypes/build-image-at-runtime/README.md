# Prototype: Build image at runtime (BIAR)

We are building flexible coding environments based on the user configuration using the Nix package manager.

The image for the coding environment is rebuilt every time the configuration changes. These changes are reflected in the image tag, the hash of the user configuration. The image name is the base configuration hash (the same for all images). A base and user configuration together uniquely identifies the corresponding image and tag.

This prototype will build an image from the dependencies in the config files specified in the `userConfig` array of `config.json`. The files in the `workdir/local.nix` will be available in the environment that is started once the image is built. Preconfigured configurations are available in the `env` folder, which you can change to remove/include packages.

You can search for predefined packages (by the Nix community) at [Nixpkgs](https://search.nixos.org/packages?channel=21.11). You can also define custom packages, for example, if you need a specific version of a package that is not available in Nixpkgs. You can find a guide on how to do this for a Python package in the 17.27.1.2.1. section [here](https://nixos.org/manual/nixpkgs/stable/#python)

## Getting Started

These instructions will give you a copy of the project up and running on
your local machine for development and testing purposes.

### Prerequisites

Requirements for the software and other tools to build, test, and push

- [Nix package manager (version: 2.7.0)](https://nixos.org/download.html)
- [Docker desktop (version: 4.6.1)](https://docs.docker.com/desktop/)

A Linux host machine is preferred. You can install a remote builder to cross-compile the builder image if you are not running a Linux host machine. The instructions for this are here: (https://github.com/LnL7/nix-docker#running-as-a-remote-builder)

### Installing

Clone this repository, then:

```bash
cd nix-docker-builder
```

#### Set up a Docker Registry

You need access to a Docker registry to push and pull the images. You can use either a local or remote public/private registry.

If you don't have one registry already, the instructions are here: (https://docs.docker.com/registry/deploying/).

After setting up a registry, you need to change the variables in the `config.json` file.
Change the `DOCKER_REGISTRY_HOST` variable to your registry name (default is `localhost:5000`).

- If you are running a registry on **localhost**, then the `DOCKER_REGISTRY_CONTAINER` variable needs to be of the form: `host.docker.internal:<PORT>` to allow docker desktop to access the host network from inside the builder container. [Further reference to connect a container to localhost](https://www.cloudsavvyit.com/14114/how-to-connect-to-localhost-within-a-docker-container/).
- otherwise (when using a **remote** registry), set the `DOCKER_REGISTRY_CONTAINER` variable to the same value as `DOCKER_REGISTRY_HOST`. You must also change the `skopeo` command in the [default.nix](https://gitlab.inf.ethz.ch/OU-LECTURERS/student-work/romeo-stoll/prototypes/-/blob/main/nix-docker-builder/default.nix) file to authenticate the push to your remote registry. Add the flag: `--dest-creds="USERNAME":"PASSWORD" \` to both `skopeo copy` commands in the file.

## Step by step

### Creating the builder container

This step has to be done **once** (unless you want to change the configuration of the builder image) and can take a few minutes.

The _scripts/run-builder.sh_ script creates a `nix-builder`-image. With this image, we create a data container called `BIAR-data-container` to persist the Nix store over the container lifecycle, manage the Nix store and allow parallel builds with a shared store.
The command for all this is:

```bash
./scripts/run-builder.sh create
```

### Building the environment image

This step has to be done every time the configuration changes and can take a few minutes if the build cache is empty and depending on your registry.

Using the _scripts/run-image.sh_ script, you can run the builder to build a new image with:

```bash
./scripts/run-image.sh build
```

This command builds a new image and streams it (by default) to the Docker registry. You can also build a layered image; run `./scripts/run-image.sh -h` to see the available options.

### Pulling the image from the registry and starting a new container from it

To pull the image from the registry to the host, use:

```bash
./scripts/run-image.sh pull
```

If you are using the `python.nix` preset file for your image, then you can run the Python environment and execute the script in `workdir/user/hello_world.py` with:

```bash
./scripts/run-image.sh run python hello_world.py
```

You can also start the container interactively with the command: `./scripts/run-image.sh run`.

Pulling and running of the image can be combined as:

```bash
./scripts/run-image.sh pull run python hello_world.py
```

## Authors

- **Romeo Stoll** -

## License
