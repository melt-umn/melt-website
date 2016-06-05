#!/bin/bash

echo "Test script to copy stuff to live top-level directory, incrementally..."

cd /web/research/melt.cs.umn.edu
chmod -R 755 alpha

newgrp melt
umask 002

# don't overwrite existing js files
cp alpha/js/* js

cp -R  alpha/css .

cp -R alpha/people .

cp -R alpha/ableC .

exit
