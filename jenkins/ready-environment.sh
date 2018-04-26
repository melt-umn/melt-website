#!/bin/bash

set -eu

if [ $0 != "jenkins/ready-environment.sh" ]; then
  echo "Run as jenkins/ready-environment.sh"
  exit 1
fi

GEMDIR=vendor/globalgem
BUNDLEDIR=vendor/bundle

mkdir -p vendor

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


