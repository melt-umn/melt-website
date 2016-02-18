#!/bin/bash

# Remove .git directory
rm -rf .git

# Install gems
echo $'Updating ruby gems...\n'
bundle install --path vendor/bundle

# Clone all other repos and remove their .git folders
echo $'Pulling updates to the Silver documentation...\n'
git clone https://github.umn.edu/melt/silver-wiki-jekyll.git silver
rm -rf !$/.git

# TODO: Will need to add repos and then script to do pull
#echo $'Pulling updates to the Copper documentation...\n'
#git clone
#rm -Rf !$/.git

# Run the python script to generate the navigation menu
echo $'Generating navigation menu...\n'
python3 menu-builder.py

# Run jekyll to build the new site
echo $'\nBuilding with jekyll...\n'
bundle exec jekyll build --destination ../build # TODO: Change the destination path, or copy from build to the melt root folder

