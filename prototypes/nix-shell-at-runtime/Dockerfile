ARG USER=runner
ARG UID=1000
ARG GID=${UID}
ARG NIX_VERSION=nix-2.7.0
FROM debian:stable-slim as base

ARG USER
ARG UID
ARG GID
ARG NIX_VERSION
ARG NIX_INSTALLER=https://releases.nixos.org/nix/${NIX_VERSION}/install

ENV HOME=/home/${USER} \
  SCRIPTDIR=./scripts \
  CONFIGDIR=./configs

# Set shell and check for pipe fails
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install deps required by Nix installer
RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends \
  ca-certificates \
  curl \
  sudo \
  xz-utils

# Create user
RUN groupadd -g ${GID} ${USER} && \
  useradd -u ${UID} -g ${GID} -G sudo -m ${USER} -s /bin/bash

# Configure sudo and Nix
RUN sed -i 's/%sudo.*ALL/%sudo   ALL=(ALL:ALL) NOPASSWD:ALL/' /etc/sudoers && \
  echo "sandbox = false" > /etc/nix.conf && \
  echo "experimental-features = nix-command flakes" >> /etc/nix.conf

# Install Nix
WORKDIR ${HOME}
USER ${USER}
ENV USER=${USER}
ENV NIX_CONF_DIR /etc
# Install Nix in single-user mode: sets up Nix store and profile
RUN curl -L ${NIX_INSTALLER} | sh && \
    . ${HOME}/.nix-profile/etc/profile.d/nix.sh && \
    nix --version
# Copy configs
RUN mkdir -p ${CONFIGDIR}
COPY --chown=${USER}:${USER} env/bench-cpp.nix ${CONFIGDIR}/bench-cpp.nix
COPY --chown=${USER}:${USER} env/bench-python.nix ${CONFIGDIR}/bench-python.nix
COPY --chown=${USER}:${USER} env/cpp.nix ${CONFIGDIR}/cpp.nix
COPY --chown=${USER}:${USER} env/python.nix ${CONFIGDIR}/python.nix

# Copy nix helpers
RUN mkdir -p ${SCRIPTDIR}
COPY --chown=${USER}:${USER} nix/nixproxy.nix ${SCRIPTDIR}/nixproxy.nix
COPY --chown=${USER}:${USER} nix/sources.nix ${SCRIPTDIR}/sources.nix
COPY --chown=${USER}:${USER} nix/sources.json ${SCRIPTDIR}/sources.json

FROM debian:stable-slim

ARG USER
ARG UID
ARG GID

ENV HOME=/home/${USER} \
    NIX_CONF_DIR=/etc \
    WORKDIR=/home/runner/projectfiles \
    CONFIGDIR=/home/runner/configs \
    SCRIPTDIR=/home/runner/scripts

## Install nix deps
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends \
  ca-certificates \
  git \
  locales \
  sudo && \
  rm -rf /var/lib/apt/lists/*

# Create priviledged user: runner
RUN groupadd -g ${GID} ${USER} && \
  useradd -u ${UID} -g ${GID} -G sudo -m ${USER} -s /bin/bash
COPY --from=base --chown=${USER}:${USER} ${HOME} ${HOME}

# Configure en_US.UTF-8 locale
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
  locale-gen

# Configure sudo
RUN sed -i 's/%sudo.*ALL/%sudo   ALL=(ALL:ALL) NOPASSWD:ALL/' /etc/sudoers

# Copy nix and configs
COPY --from=base /nix /nix
COPY --from=base /etc/nix.conf /etc/nix.conf

# Copy entrypoint. Root user needed for chmod
USER root
WORKDIR ${HOME}
COPY --chown=${USER}:${USER} ./entrypoint.sh ./entrypoint.sh
RUN chmod +x ./entrypoint.sh

# create workdir
RUN mkdir -pm 750 ${WORKDIR} \
  && chown ${USER}:${USER} ${WORKDIR}

USER ${USER}
ENV USER=${USER} \
    PATH=${HOME}/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/nix/var/nix/profiles/default/sbin:/bin:/sbin:/usr/bin:/usr/sbin
WORKDIR ${WORKDIR}
RUN . ${HOME}/.nix-profile/etc/profile.d/nix.sh \
  && nix-env -iA nixpkgs.cached-nix-shell

CMD ["bash"]
ENTRYPOINT [ "/home/runner/entrypoint.sh" ]

VOLUME /nix
VOLUME /${USER}/.cache/cached-nix-shell