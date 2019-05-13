#!/bin/bash

set -e

function die {
  echo $@ >&2
  exit 1
}

function usage {
  cat <<USAGE
Usage: $(basename "$0") <dest-file> <log-file-gz-or-glob-pattern-to-gz> ...

Combines logs matching pattern as well as the current go-server.log into a single file
USAGE
}

function catlogs {
  if [ $# -lt 2 ]; then
    usage
  fi

  local dest=$1
  shift

  local logdir=$(cd `dirname "$1"` && pwd) # infer path to go-server.log

  cat /dev/null > "$dest" && {
    for arch in $(ls $@ | sort -t . -n -k 4 | xargs); do
      if ! gunzip -c "$arch" >> "$dest"; then
        echo "Had problems unpacking $arch" >&2
      else
        echo "Consumed $arch"
      fi
    done
  } && cat "$logdir/go-server.log" >> "$dest"
}

catlogs $@
