#!/bin/bash

# Run from 'melt-website'
# TODO: test existence of _temp/silver directory.

cd _temp/silver

# Get any updates to Silver documentation in source files that will be
# used to generate documentation.
git pull

# Run the script generate documentation
./generate-documentation

# Copy the documentation to the silver doc directory
mkdir -p ../../silver/doc
cp -rf documentation/* ../../silver/doc


# TODO: We will eventually collect documentation from other
# repositories, suchs those for Copper and ableC.  We Will need to do
# that work here.


# Go back to 'melt-website'
cd ../..
./step4-run-jekyll.sh $1

