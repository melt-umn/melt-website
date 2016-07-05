#!/bin/bash

# stop on error
set -e

rm -Rf melt-website

git clone git@github.umn.edu:melt/melt-website.git

cd melt-website

rsync -a --exclude README.md gitbot-home-directory/ ~

./step2-install-gems-silver.sh "$1"
