# Prototype: Nix docker builder

For building flexible coding environments based on the user configuration using Nix package manager.

The image for the coding environment is rebuilt every time the configuration changes. The image name and tag reflect these changes. The image name is the hash of the predefined configuration files (which rarely change). And the image tag is the hash of the user configuration, which changes more often. Thus a configuration uniquely identifies the corresponding image.

This prototype will build by default a python environment for the user, where the predefined configurations are specified in the nix files of the `env` folder. The user can additionally specify packages (as derivations) in the `workdir/local.nix` file, which will get included in the final _env_ image. You can specify the configurations that the builder should use in the `userConfig` array of `config.json`.

You can search for predefined packages (by the Nix community) at [Nixpkgs](https://search.nixos.org/packages?channel=21.11).

## Getting Started

These instructions will give you a copy of the project up and running on
your local machine for development and testing purposes.

### Prerequisites

Requirements for the software and other tools to build, test, and push

- [Nix package manager (version: 2.7.0)](https://nixos.org/download.html)
- [Docker desktop (version: 4.6.1)](https://docs.docker.com/desktop/)

If you are not running a Linux host machine, you have two options:

- install a remote builder to crosscompile the builder image. The instructions for this are here: (https://github.com/LnL7/nix-docker#running-as-a-remote-builder)
- use the provided builder tarball and load it into docker (this can be done by running: `docker load < builder-tarball`). This is easier but doesn't allow you to recompile the builder image. Thus if you delete the builder image some scripts may not work anymore.

### Installing

Clone this repository, then:

```bash
cd nix-docker-builder
```

#### Set up a Docker Registry

You need to access a Docker registry to push and pull the images. You can use either a local or remote public/private registry.

If you don't have one registry already, the instructions are here: (https://docs.docker.com/registry/deploying/).

After setting up a registry, you need to change the variables in the `config.json` file.
Change the `DOCKER_REGISTRY_HOST` variable to your registry name (default is `localhost:5000`).

- If you are running a registry on **localhost**, then the `DOCKER_REGISTRY_CONTAINER` variable needs to be of the form: `host.docker.internal:<PORT>` to allow docker desktop to access the host network from inside the builder container. [Further reference to connect a container to localhost](https://www.cloudsavvyit.com/14114/how-to-connect-to-localhost-within-a-docker-container/).
- otherwise (when using a **remote** registry), set the `DOCKER_REGISTRY_CONTAINER` variable to the same value as `DOCKER_REGISTRY_HOST`. You also need to change the `skopeo` command in the [default.nix](https://gitlab.inf.ethz.ch/OU-LECTURERS/student-work/romeo-stoll/prototypes/-/blob/main/nix-docker-builder/default.nix) file to authenticate the push to your remote registry. Add the flag: `--dest-creds="USERNAME":"PASSWORD" \` to both `skopeo copy` commands in the file.

## Step by step

### Creating the builder container

This step has to be done **once** (unless you want to change the configuration of the builder image) and can take a few minutes.

The _scripts/run-builder.sh_ script creates a Nix-builder image. This image creates a data container to persist the Nix-store between builds (and allow parallel builds with a shared store).
The command for all this is:

```bash
./scripts/run-builder.sh create
```

### Building the environment image

This step has to be done every time the configuration changes and can take a few minutes if the build cache is empty and depending on your registry.

Using the _scripts/run-image.sh_ script, you can run the builder to build a new _environment_ image with:

```bash
./scripts/run-image.sh build
```

This command builds a new _env_ image and streams it (by default) to the Docker registry. You can also build a layered image; run `./scripts/run-image.sh -h` to see the available options.

### Pulling the _env_ image from the registry and starting a new container from it

To pull the _environment_ image from the registry to the host, use:

```bash
./scripts/run-image.sh pull
```

To run the python _env_ image in a container and execute the python script in `workdir/user/hello_world.py`, run:

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
  [rstol](https://github.com/rstol)

## License
