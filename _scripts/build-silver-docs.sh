#!/bin/bash

set -eu

if [ $0 != "_scripts/build-silver-docs.sh" ]; then
  echo "Run as _scripts/build-silver-docs.sh"
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

./support/bin/silver --dont-translate --doc --clean silver:extension:doc:extra

rm ./build.xml

mkdir -p "$ORIG/silver/gen/"
cp -r generated/doc/* "$ORIG/silver/gen/"

rm -rf generated

