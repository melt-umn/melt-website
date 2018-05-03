#!/bin/bash

set -eu

if [ $0 != "jenkins/build-silver-docs.sh" ]; then
  echo "Run as jenkins/build-silver-docs.sh"
  exit 1
fi

ORIG=$(pwd)
SVWORKSPACE=/export/scratch/melt-jenkins/custom-silver
SV=vendor/silver

if [ ! -d "$SVWORKSPACE" ]; then
  echo "Expected to run on coldpress. $SVWORKSPACE not found"
  exit 1
fi

if [ -d "$SV" ]; then
  rm -rf "$SV"
fi

cp -r "$SVWORKSPACE" "$SV"

cd "$SV"

# Run silver to generate some docs
mkdir -p generated

./support/bin/silver --doc --clean silver:extension:doc:extra

rm ./build.xml ./silver.extension.doc.extra.jar

cp -rf generated/doc/silver/* documentation/gen/silver
cp -rf generated/doc/core documentation/gen
cp -rf generated/doc/lib/* documentation/gen/lib

rm -rf generated

# We don't want this file copied over
rm -f documentation/README.md

# Copy docs from silver back to the website
mkdir -p "$ORIG/silver/doc"
cp -rf documentation/* "$ORIG/silver/doc"

