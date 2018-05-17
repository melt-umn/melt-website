#!/bin/bash

set -eu

# By default, build. But maybe so something else
: ${JEKYLL_COMMAND:="build"}

if [ $0 != "_scripts/build-jekyll-site.sh" ]; then
  echo "Run as _scripts/build-jekyll-site.sh"
  exit 1
fi

GEMDIR=vendor/globalgem
export PATH="$(pwd)/$GEMDIR/bin:$PATH"
export GEM_PATH="$GEMDIR"

echo "Updating metadata..."
python3 _scripts/menu-builder.py

echo "Building site..."
bundle exec jekyll ${JEKYLL_COMMAND}

# Make group permissions same as user, will be preserved when copied later
if [ $JEKYLL_COMMAND = "build" ]; then
  chmod -R g=u _site
fi
