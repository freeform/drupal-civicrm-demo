#!/bin/bash

#
# Deploy CiviCRM
#
# # Need to put the site path to the live site in comment: "|/var/www/ssc.ca/httpdocs"

set -o errexit

COMMENT=$1

# Split up comment to get the site path.
IFS='|'
read -ra CHUNKS <<< "$COMMENT"
SITEPATH="${CHUNKS[1]}"
IFS=' ' # Reset to default value after usage

# Refresh the database from live.
# @todo get the path to live.
./civi-db-export.sh --sitepath="$SITEPATH" --destination="/tmp/civi_db_tmp.sql.gz"
./civi-db-import.sh --file="/tmp/civi_db_tmp.sql.gz"
rm /tmp/civi_db_tmp.sql.gz