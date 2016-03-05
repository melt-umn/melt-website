#!/bin/bash

# Run from 'melt-website'
# TODO: check this

# Note that the website is currently (see step4) put into a 'build'
# directory that is just above the 'melt-website' repository
# directory.

rm -Rf /web/research/melt.cs.umn.edu/alpha

mv ../build /web/research/melt.cs.umn.edu/alpha

