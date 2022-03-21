Minimal Nix Docker
==================

This gist creates such a minimal (yet opinionated) Nix image for Docker that
the image will mostly the files included in the Nix installer and a copy of the
latest Nixpkgs.


Bootstrapping
-------------

Build a Docker image named *nix* using the provided Docker based build chain:

.. code:: sh

   $ git clone https://gist.github.com/datakurre/a5d95794ce73c28f6d2f
   $ cd a5d95794ce73c28f6d2f
   $ IMAGE_NAME=nix IMAGE_TAG=latest make

Create a Docker data container named *nix* to use shared persistent ``/nix``
for all run containers.

.. code::

   $ docker create --name nix -v /nix nix sh

To know more about where the nix data gets stored with this setup,
please, read Docker documentation about `managing data in containers`__.

__ https://docs.docker.com/engine/userguide/dockervolumes/


Examples of use
---------------

Running a Python interpreter with some packages:

.. code:: sh

   $ docker run --rm --volumes-from=nix -ti nix \
            nix-shell -p pythonPackages.pillow --run python

Running a Haskell Jupyter notebook with mounted context:

.. code:: sh

   $ mkdir .jupyter
   $ echo "c.NotebookApp.ip = '*'" > .jupyter/jupyter_notebook_config.py
   $ docker run --rm --volumes-from=nix -ti \
            -v $PWD:/mnt -w /mnt -e HOME=/mnt -p 8888 nix \
            nix-shell -p ihaskell --run "ihaskell-notebook"

Building a docker image by using Nix docker tools based expression:

.. code:: sh

   $ docker run --rm --volumes-from=nix -v $PWD:/build:ro -w /build nix \
            bash -c "cat \`nix-build release.nix -A image --no-out-link \`" \
            | docker load


Adding ``--help`` for nix-commands:

.. code:: sh

   $ docker run --rm --volumes-from=nix nix nix-env -i man
   $ docker run --rm --volumes-from=nix nix nix-env --help

Purging nix-store cache:

.. code:: sh

   $ docker run --rm --volumes-from=nix nix nix-collect-garbage -d


Some technical details
----------------------

* Nixpkgs is stored at ``/var/nixpkgs`` so you can override it with your
  own local version with ``-v /local/path/to/my/nixpkgs:/var/nixpkgs``.

* By default ``nix-env`` operates on the default profile at
  ``/nix/var/nix/profiles/default``, which is conveniently symlinked into
  ``/usr/local``.

* For convenience, the image also contains:

  - Bash build at ``/nix/var/nix/profiles/bash`` symlinked into ``/bin``.
  - All the other binaries from Nix-installer are symlinked into ``/usr/bin``.
  - CACerts build at ``/nix/var/nix/profiles/cacert``.

  All the above are simple symlinks to the packages at Nix store provided by
  the Nix installer. They are included in the default PATH, but only after the
  default profile.

Of course, all the above could be customized simply by forking this recipe.
