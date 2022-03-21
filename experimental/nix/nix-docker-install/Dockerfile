FROM nixos/nix

RUN nix-channel --update

RUN mkdir -p ./home
RUN chown 1000 ./home
COPY ./shell.nix ./home
COPY ./user_defined.nix ./home

WORKDIR /home

CMD ["nix-shell"]

# Install packages required to add users and install Nix
# RUN apt-get update && apt-get install -y curl bzip2 adduser

# Add the user aaronlevin for security reasons and for Nix
# RUN adduser --disabled-password --gecos '' aaronlevin

# Nix requires ownership of /nix.
# RUN mkdir -m 0755 /nix && chown runner /nix

# RUN chown -R runner:runner /home/runner

# # Change docker user to aaronlevin
# USER aaronlevin

# # Set some environment variables for Docker and Nix
# ENV USER aaronlevin

# # Change our working directory to $HOME
# WORKDIR /home/aaronlevin

# # install Nix
# RUN curl https://nixos.org/nix/install | sh

# # update the nix channels
# # Note: nix.sh sets some environment variables. Unfortunately in Docker
# # environment variables don't persist across `RUN` commands
# # without using Docker's own `ENV` command, so we need to prefix
# # our nix commands with `. .nix-profile/etc/profile.d/nix.sh` to ensure
# # nix manages our $PATH appropriately.
# RUN . .nix-profile/etc/profile.d/nix.sh && nix-channel --update

# # Copy our nix expression into the container
# COPY default.nix /home/aaronlevin/

# # run nix-build to pull the
# RUN . .nix-profile/etc/profile.d/nix.sh && nix-build

# run our application
# CMD ["./results/bin/run"]