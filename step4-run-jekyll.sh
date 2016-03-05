#!/bin/bash

# Run from 'melt-website'

# Run the python script to generate the navigation menu
echo $'\nGenerating navigation menu...\n'
python3 menu-builder.py

# Run jekyll to build the new site
echo $'\nBuilding with jekyll...\n'

# TODO: Change the destination path, or copy from build to the melt root folder
bundle exec jekyll build --destination ../build 


./step5-install-site.sh "$1"

