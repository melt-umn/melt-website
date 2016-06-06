#!/bin/bash

# Run from 'melt-website'

# After step 3, hand-written and generated MarkDown files are in the
# `silver/documentation' directory of the _temp silver repo.

# Get any updates to Silver documentation in hand-written Markdown
# in silver/documentation.
cd _temp/silver
git pull

# Copy the documentation to the silver/doc directory
mkdir -p ../../silver/doc
cp -rf documentation/* ../../silver/doc

cd ../../


# Get any updates from hand-written Markdown in melt-website
git pull

# Run the python script to generate the navigation menu
echo $'\nGenerating navigation menu...\n'
python3 menu-builder.py

# Run jekyll to build the new site
echo $'\nBuilding with jekyll...\n'

# TODO: Change the destination path, or copy from build to the melt root folder

rm -Rf /web/research/melt.cs.umn.edu/alpha

bundle exec jekyll build --destination /web/research/melt.cs.umn.edu/alpha


if [ -z "$1" ]; then
    # TODO: check that "$1" is actually "--install" instead of just not empty.
    echo ""
    echo "********  Site installed in default \"alpha\" directory."
else
    ./step5-install-site.sh "$1"
fi
