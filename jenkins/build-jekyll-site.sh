#!/bin/bash

set -eu

if [ $0 != "jenkins/build-jekyll-site.sh" ]; then
  echo "Run as jenkins/build-jekyll-site.sh"
  exit 1
fi

GEMDIR=vendor/globalgem
export PATH="$(pwd)/$GEMDIR/bin:$PATH"
export GEM_PATH="$GEMDIR"

echo "Updating metadata..."
python3 menu-builder.py

# Preserve group-writable in what we generate here, so the copy later is easier
umask 002

echo "Building site..."
bundle exec jekyll build


