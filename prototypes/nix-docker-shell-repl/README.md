# Prototype: Nix docker shell repl

For building flexible coding environments based on the user configuration using Nix package manager.

The image for the repl environment is build once and has a name based on the Nix version used. Versioning of the image is currently not used and the image has tag `latest`.

This prototype will create by default a python environment for the user, where the predefined configurations are specified in the nix files of the `env` folder. The user can additionally specify packages (as derivations) in the `workdir/local.nix` file, which will get included in the _environment_ created by the `nix-shell`. You can specify the configuration files that the nix-shell should use in the `presetPath` and `localPath` of [config.json](https://gitlab.inf.ethz.ch/OU-LECTURERS/student-work/romeo-stoll/prototypes/-/blob/main/nix-docker-shell-repl/config.json).

You can search for predefined packages (by the Nix community) at [Nixpkgs](https://search.nixos.org/packages?channel=21.11).

## Getting Started

These instructions will give you a copy of the project up and running on
your local machine for development and testing purposes.

### Prerequisites

Requirements for the software and other tools to build, test, and push

- [Nix package manager (version: 2.7.0)](https://nixos.org/download.html)
- [Docker desktop (version: 4.6.1)](https://docs.docker.com/desktop/)

If you are not running a Linux host machine, you need to install a remote builder to crosscompile the builder image. The instructions for this are here: (https://github.com/LnL7/nix-docker#running-as-a-remote-builder)

### Installing

Clone this repository, then:

```bash
cd nix-docker-shell-repl
```

#### (OPTIONAL) Set up a Docker Registry

If you want to use a Docker registry to push and pull the images, you need to use a linux host machine and you can use either a local or remote public/private registry.
If you don't have one registry already, the instructions are here: (https://docs.docker.com/registry/deploying/).

After setting up a registry, you need to change the variables in the `config.json` file.
Change the `DOCKER_REGISTRY_HOST` variable to your registry name (default is `localhost:5000`).

- If you are running a registry **localhost** , then add `--add-host host.docker.internal:host-gateway` to both `docker run` commands im the run-image.sh file. [Further reference to connect a container to localhost](https://www.cloudsavvyit.com/14114/how-to-connect-to-localhost-within-a-docker-container/).
- otherwise (when using a **remote** registry), you may need to change the `skopeo` command in the [default.nix](https://gitlab.inf.ethz.ch/OU-LECTURERS/student-work/romeo-stoll/prototypes/-/blob/main/nix-docker-shell-repl/default.nix) file to authenticate the push to your remote registry. Add the flag: `--dest-creds="USERNAME":"PASSWORD" \` to both `skopeo copy` commands in the file.

## Step by step

### Creating the image container

This step has to be done **once** (unless you change the default.nix configuration).

The _scripts/run-image.sh_ script first creates an _env_ image from the default.nix file. Second, it creates data container to persist the Nix-store and the nix-shell between subsequent image startups.
The command for all this is:

```bash
./scripts/run-image.sh create
```

If you want to push the image to a registry then use the following command instead of the above:

```bash
./scripts/run-image.sh create push
```

### Running the _env_ image

To run the python _env_ image in a container and execute the python script in `workdir/user/hello_world.py`, run:

```bash
./scripts/run-image.sh run cached-nix-shell-cmd 'python hello_world.py'
```

If you want to use the default (uncached) nix-shell then use:

```bash
./scripts/run-image.sh run nix-shell-cmd 'python hello_world.py'
```

You can start a nix-shell without executing a script by running either:
`./scripts/run-image.sh run nix-shell` or `./scripts/run-image.sh run cached-nix-shell`

You can also start an interactive bash shell inside the container with the command: `./scripts/run-image.sh run`.

### Prebuilding the dependencies in the nix store

You can prebuild the nix store before executing the nix-shell.
Your first nix-shell execution will be faster with a prebuild store.

```bash
./scripts/run-image.sh prebuild-store
```

> Run `./scripts/run-image.sh -h` to see the other available commands and options.

## Authors

- **Romeo Stoll** -
  [rstol](https://github.com/rstol)

## License
