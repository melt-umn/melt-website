#!/bin/bash

# example cron config:
# */10 * * * * /export/scratch/melt-jenkins/custom-website-dump/cron-install-site.sh

# redirect this script's output to log file, not stdout
exec > /export/scratch/gitbot-deletable-website-log 2>&1

set -eu

WEBSITE=/web/research/melt.cs.umn.edu
JENKINS_DUMP=/export/scratch/melt-jenkins/custom-website-dump

# On occasion, NFS goes down, just exit gracefully if so

if [ ! -d $WEBSITE ] || [ ! -d $JENKINS_DUMP ]; then
  echo "NFS down?"
  exit 1
fi

# We MUST leave files in the destination alone if they're not in the source
# (consider, e.g., downloads)

# -u Only copy if the source file is newer than the destination file (reduce IO)
# --remove-destination  delete before copying so that we take ownership of the file (thus can chgrp/mod)

newgrp cs-melt << EOF
  umask 002
  cp -u --remove-destination $JENKINS_DUMP/* $WEBSITE/
EOF

# Don't leave our script in the website
rm $WEBSITE/cron-install-site.sh

# fix permissions
#chgrp -R cs-melt $WEBSITE
#chmod -R g+rwX,o-w $WEBSITE


