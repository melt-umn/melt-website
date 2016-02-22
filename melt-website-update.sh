#!/bin/bash

# Remove .git directory
rm -rf .git

# Install gems
echo $'\nUpdating ruby gems...\n'
bundle install --path vendor/bundle

# Clone and build Silver documentation
echo $'\nBuilding silver documentation\n'
mkdir scripttemp
cd scripttemp
git clone https://github.com/melt-umn/silver.git
git checkout feature/docgen #This needs to be taken out when we stop developing on the feature branch
cd silver
#Compile Silver
./self-compile --doc --clean
#Copy the generated documentation into the 
cp -rf generated/doc/silver documentation/ref/generated
cp -rf generated/doc/core documentation/ref/generated
#Copy the entire documentation folder into the Silver folder
cp -rf documentation/* ../../silver/doc

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

# Kill myself


