#!/bin/bash

set -eu

FROM=_site
TO=/export/scratch/melt-jenkins/custom-website-dump

mkdir -p "$TO"

# slashes are meaningful
rsync -a --delete "$FROM/" "$TO/"
# -a is archive mode: rlptgoD (recurse, links, perms, time, group, owner, devices)
# --delete  Remove files from destination not in src

