#!/bin/bash

# Run from 'melt-website'

# Install gems
echo $'\nUpdating ruby gems...\n'
bundle install --path vendor/bundle --jobs 10

# Clone and build documentation branch of Silver
echo $'\nBuilding documentation branch of Silver\n'

rm -Rf _temp
mkdir _temp
cd _temp
git clone https://github.com/melt-umn/silver.git
cd silver

git checkout feature/docgen 

./fetch-jars

#Compile Silver to work with documentation
./self-compile

cp build/silver.composed.Default.jar jars



# Go back to 'melt-website' and run step 3
cd ../..
./step3-generate-docs.sh "$1"


