#!/bin/bash

set -eu

if [ $0 != "jenkins/deploy-site.sh" ]; then
  echo "Run as jenkins/deploy-site.sh"
  exit 1
fi

FROM=_site
TO=/export/scratch/melt-jenkins/custom-website-dump

mkdir -p "$TO"

# We also want to copy ourselves
cp jenkins/cron-install-site.sh "$FROM/"

### Let's do the copy:

# slashes are meaningful
rsync -a --delete "$FROM/" "$TO/"
# -a is archive mode: rlptgoD (recurse, links, perms, time, group, owner, devices)
# --delete  Remove files from destination not in src

