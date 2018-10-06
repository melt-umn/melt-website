#!/bin/bash

set -eu

if [ $0 != "_scripts/ready-environment.sh" ]; then
  echo "Run as _scripts/ready-environment.sh"
  exit 1
fi

GEMDIR=vendor/globalgem
BUNDLEDIR=vendor/bundle

if [ ! -e vendor ]; then
  if [ "$USER" = "jenkins" ]; then
    mkdir vendor
  elif [[ "$(hostname -f)" = *.cs.umn.edu ]]; then
    LOCALCACHE="/export/scratch/$USER-jekyll-cache"
    echo "Creating your local cache: $LOCALCACHE"
    mkdir "$LOCALCACHE"
    ln -s "$LOCALCACHE" vendor
  else
    echo "Non-CS.UMN machine. Creating a local 'vendor' directory."
    echo "--------------------------------------------------------"
    echo
    mkdir vendor
  fi
fi

### Step 1: use gem to get bundler
### To avoid stepping on anything else, we're going to install it to
### the special $GEMDIR path in vendor/

if [ ! -x "$GEMDIR/bin/bundle" ]; then
  echo "Installing bundler..."
  gem install --install-dir "$GEMDIR" bundler
fi

# This is what we need to do to get `bundle` in PATH and be able to run it
export PATH="$(pwd)/$GEMDIR/bin:$PATH"
export GEM_PATH="$GEMDIR"

### Step 2: Use bundler to install the gems we want
### Here using $BUNDLEDIR to install these locally in vendor/ again

echo "Getting the right gems..."
bundle install --path "$BUNDLEDIR" --jobs 10

# Verify everything is good
bundle exec jekyll --version


