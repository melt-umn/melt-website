#!/bin/bash

# Run from 'melt-website'

# Get any updates to Silver documentation in hand-written Markdown
# in silver/documentation.
cd _temp/silver
git pull
cd ../../

# Get any updates from hand-written Markdown in melt-website
git pull

# Run the python script to generate the navigation menu
echo $'\nGenerating navigation menu...\n'
python3 menu-builder.py

# Run jekyll to build the new site
echo $'\nBuilding with jekyll...\n'

# TODO: Change the destination path, or copy from build to the melt root folder
bundle exec jekyll build --destination ../build 


if [ -z "$1" ]; then
    # TODO: check that "$1" is actually "--install" instead of just not empty.
    echo ""
    echo "Site installed in default \"build\" directory."
else
    ./step5-install-site.sh "$1"
fi
