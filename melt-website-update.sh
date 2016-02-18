#!/bin/bash

# Remove .git directory
rm -rf .git

# Install gems
echo $'\nUpdating ruby gems...\n'
bundle install --path vendor/bundle

# Clone all other repos and remove their .git folders
echo $'\nPulling updates to the Silver documentation...\n'
cd silver
git clone https://github.umn.edu/melt/silver-wiki-jekyll.git silver
rm -rf !$/.git
cd ..

# TODO: Will need to add repos and then script to do pull
#echo $'Pulling updates to the Copper documentation...\n'
#cd
#git clone
#rm -Rf !$/.git
#cd ..

# Run the python script to generate the navigation menu
echo $'\nGenerating navigation menu...\n'
python3 menu-builder.py

# Run jekyll to build the new site
echo $'\nBuilding with jekyll...\n'
bundle exec jekyll build --destination ../build # TODO: Change the destination path, or copy from build to the melt root folder

