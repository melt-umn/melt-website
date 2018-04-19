#!/bin/bash

set -eu

GEMDIR=vendor/globalgem
BUNDLEDIR=vendor/bundle

mkdir -p vendor

### Step 1: use gem to get bundler
if [ ! -x "$GEMDIR/bin/bundle" ]; then
  echo "Installing bundler..."
  gem install --install-dir "$GEMDIR" bundler
fi

# Get 'bundle' in PATH
export PATH="$(pwd)/$GEMDIR/bin:$PATH"
export GEM_PATH="$GEMDIR"

### Step 2: Install the gems we want
echo "Getting the right gems..."
bundle install --path "$BUNDLEDIR" --jobs 10

# Verify everything is good
bundle exec jekyll --version

# Of course, jenkins doesn't get the modified PATH, so remember to add
# `./vendor/globalgem/bin` or `bundle` won't show up.

