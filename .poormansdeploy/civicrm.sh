#!/bin/bash

#
# Deploy CiviCRM
#
# See https://docs.civicrm.org/installation/en/latest/drupal8

# Localisation files cannot be installed via composer. Use a manual
# process.
# Need to have the version like this at the end of the comment: "|5.41.2"

set -o errexit

COMMENT=$1
URL="https://download.civicrm.org/civicrm-VERSION-l10n.tar.gz"
FILE="civicrm-VERSION-l10n.tar.gz"
# Split up comment to get the CiviCRM version.
IFS='|'
read -ra CHUNKS <<< "$COMMENT"
VERSION="${CHUNKS[1]}"
IFS=' ' # Reset to default value after usage

URL=${URL/VERSION/$VERSION}
FILE=${FILE/VERSION/$VERSION}

cd ..
wget "$URL"
tar -zxvf "$FILE"
cd civicrm/
cp -R l10n/ ../vendor/civicrm/civicrm-core/
cp -R sql/ ../vendor/civicrm/civicrm-core/
cd ..
rm -rf civicrm/
rm "$FILE"
echo "Installed localisation files, and cleaned up temporary files."