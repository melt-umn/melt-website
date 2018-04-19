#!/bin/bash

set -eu

GEMDIR=vendor/globalgem
export PATH="$(pwd)/$GEMDIR/bin:$PATH"
export GEM_PATH="$GEMDIR"

echo "Updating metadata..."
python3 menu-builder.py

echo "Building site..."
bundle exec jekyll build


