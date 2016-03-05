#!/bin/bash

# Run from 'melt-website'
# TODO: check this

if [ -z "$1" ]; then
    echo ""
    echo "Site installed in default \"build\" directory."
else
    DEST="$1"

    rm -Rf /web/research/melt.cs.umn.edu/alpha

    mv build /web/research/melt.cs.umn.edu/alpha

fi