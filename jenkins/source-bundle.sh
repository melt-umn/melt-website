#!/bin/bash

# Source this file as ". jenkins/source-bundle.sh"

GEMDIR=vendor/globalgem

if [ ! -x $GEMDIR/bin/bundle ]; then
  echo "Didn't see bundler installed? Did you run jenkins/ready-environment.sh ?"
  exit 1
fi

export PATH="$(pwd)/$GEMDIR/bin:$PATH"
export GEM_PATH="$GEMDIR"

