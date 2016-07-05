#!/bin/bash

# stop on error
set -e

# Run from 'melt-website'
# TODO: check this

# Note that the website is currently (see step4) put into a 'build'
# directory that is just above the 'melt-website' repository
# directory.

umask 002

cd /web/research/melt.cs.umn.edu

chgrp -R melt alpha
chmod -R g=u alpha
chmod -R o=u-w alpha*

# don't overwrite existing js files
# main_left_nav.js and silver_top_nav.js to be removed later
cp alpha/js/* js


cp -R  alpha/css .

cp alpha/index.html .

cp -R alpha/people .

cp -R alpha/ableC .

cp alpha/silver/index.html silver/
cp -R alpha/silver/doc/ silver/

cp alpha/copper/index.html copper/

cp alpha/pubs/index.html pubs/

#exit
