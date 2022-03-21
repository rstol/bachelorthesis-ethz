FROM scratch
ADD nix.tar.gz /
ENV HOME="/root" TERM="linux" \
  PATH="/usr/local/bin:/usr/bin:/bin" \
  SSL_CERT_FILE="/usr/local/etc/ssl/certs/ca-bundle.crt" \
  SYSTEM_CERTIFICATE_PATH="/usr/local/etc/ssl/certs/ca-bundle.crt" \
  NIX_PATH="nixpkgs=/root/.nix-defexpr/channels/nixpkgs"
RUN /nix/store/*-nix-*/bin/nix-store --init && \
  /nix/store/*-nix-*/bin/nix-store --load-db < /nix/store/.reginfo && \
  /nix/store/*-nix-*/bin/nix-env -i \
  /nix/store/*-nix-* /nix/store/*-coreutils-* \
  /nix/store/*-curl-* /nix/store/*-cacert-* /nix/store/*-gnutar-* \
  /nix/store/*-xz-* /nix/store/*-gzip-* /nix/store/*-bzip2-* && \
  nix-channel --add http://nixos.org/channels/nixos-unstable nixpkgs && \
  nix-channel --update && \
  nix-env -i bash-interactive iana-etc which && \
  ln -sf /usr/local/bin/env /usr/bin && \
  ln -sf /usr/local/bin/bash /bin && \
  ln -sf /usr/local/bin/sh /bin && \
  ln -sf /usr/local/etc/* /etc && \
  nix-collect-garbage -d
RUN chown 0:0 -R /bin /etc /usr /var /tmp
