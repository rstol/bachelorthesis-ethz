#! /bin/sh

if test $# -gt 0; then
  if [ "$1" = 'cached-shell' ]; then
    shift
    if test $# -gt 0; then
      exec /bin/cached-nix-shell /home/runner/scripts/nixproxy.nix --pure --argstr userConfigPath "$USERCONFIGPATH" --command "$@"
    else
      exec /bin/cached-nix-shell /home/runner/scripts/nixproxy.nix --pure --argstr userConfigPath "$USERCONFIGPATH"
    fi
  elif [ "$1" = 'nix-shell' ]; then
    shift
    if test $# -gt 0; then
      exec nix-shell /home/runner/scripts/nixproxy.nix --pure --argstr userConfigPath "$USERCONFIGPATH" --command "$@"
    else
      exec nix-shell /home/runner/scripts/nixproxy.nix --pure --argstr userConfigPath "$USERCONFIGPATH"
    fi
  fi
fi

exec "$@"