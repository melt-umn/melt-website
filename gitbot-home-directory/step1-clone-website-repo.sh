#!/bin/bash

rm -Rf melt-website

git clone git@github.umn.edu:melt/melt-website.git

cd melt-website

./step2-install-gems-silver.sh "$1"
