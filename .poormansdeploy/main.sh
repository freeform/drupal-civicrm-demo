#!/bin/bash

#
# PoormansDeploy Tool - Drupal 9
#
# Version 0.1
#
# Automate various steps to ensure a consistent deployment
# process on Beanstalk.
# Inspired by https://chromatichq.com/insights/drupal-8-deployment-scripts
# and https://github.com/ChromaticHQ/ansible-deploy-drupal
#
# By default it will pull the code for the revision deployed and then clear
# the drupal cache.
# 1. If the phrase "update code only please" is in the deployment comment, then
#    it will also:
#    * make a db backup, ensure there are no uncommited config changes
#    * run composer install
#    * run update database and hooks
# 2. If: "rebuild this please" then it will also:
#    * import configuration
# 3. If "refresh civicrm from live please |/var/www/httpdocs":
#    * This is not working yet.
# 4. If "rebuild civicrm localise please |5.41.2" (or whatever version):
#    * fetch the localisation files that match the version and install
#

# @todo decide whether to run composer install on production or not. And if not,
# what to do: copy from staging? build it elsewhere?
# https://laracasts.com/discuss/channels/general-discussion/continuous-deployment-how-to-composer-install-instead-of-on-production-server-proscons
# https://docs.gitlab.com/ee/ci/examples/laravel_with_gitlab_and_envoy/#installing-dependencies-with-composer

# Beanstalk command:
#
# %REMOTE_PATH%/.poormansdeploy/main.sh %AUTO?% %TIMESTAMP_UTC% %REVISION% %REMOTE_PATH% "%COMMENT%" ENV
#
# (ENV can be DEV, STAGING. Anything else will be assumed to be LIVE and thus restricted.)

set -o errexit

AUTO_DEPLOY=$1
TIMESTAMP=$2
REVISION=$3
REMOTE_PATH=$4
COMMENT=$5
ENV=$6
WEB_DIR="$REMOTE_PATH/httpdocs"
DRUSH="$REMOTE_PATH/vendor/bin/drush"

# @todo
# Move the deployment to a build folder so that we don't have to use composer on live.
# BUILD_DIR="$REMOTE_PATH/"

cd "$REMOTE_PATH"

# Output information about the site to aid in debugging failed deployments.
"$DRUSH" core:status

if [[ $AUTO_DEPLOY == "0" ]] && [[ $COMMENT =~ "rebuild civicrm localise please |" ]]; then
  ./.poormansdeploy/civicrm-localise.sh "$COMMENT"
fi

if [[ $AUTO_DEPLOY == "0" ]] && [[ $COMMENT =~ "rebuild this please" ]]; then
  # Identify Drupal configuration changes in core or contrib updates that need
  # to be exported and may have been missed.
  OUTPUT=$("$DRUSH" config:export -y 2>&1 > /dev/null)
  echo "$OUTPUT"
  if [[ $OUTPUT =~ "active configuration is identical" ]]; then
    echo "Configuration matches the sync directory so okay to rebuild."
  else
    echo "Error: there are configuration changes in this environment that are not yet in the repo. Quitting to prevent them being overwritten."
    exit 1
  fi
fi

if [[ $AUTO_DEPLOY == "0" ]] && [[ $COMMENT =~ "rebuild this please" || $COMMENT =~ "update code only please" ]]; then
  # Backup the database.
  "$DRUSH" sql:dump --gzip --result-file=auto

  # Put the site into maintenance mode to prevent conflicts
  # from occurring during database updates.
  "$DRUSH" --root="$WEB_DIR" state:set system.maintenance_mode 1
fi

# If it's a git repo pull the latest code.
# Otherwise ignore - SFTP mode will deploy files.
if git rev-parse --git-dir > /dev/null 2>&1; then

  git checkout master
  git pull origin master
  git checkout $REVISION
fi

# if [[ $AUTO_DEPLOY == "0" ]] && [[ $COMMENT =~ "refresh civicrm from live please |" ]] && [[ $ENV == DEV || $ENV == STAGING ]]; then
#   ./.poormansdeploy/civicrm-refresh.sh "$COMMENT"
# fi

if [[ $AUTO_DEPLOY == "0" ]] && [[ $COMMENT =~ "rebuild this please" || $COMMENT =~ "update code only please" ]]; then
  # Ensure we can write to default folder.
  chmod u+w $(pwd)/httpdocs/sites/default

  # Install any updated or new packages.
  # CiviCRM requires dev packages
  composer install --no-interaction
fi

if [[ $AUTO_DEPLOY == "0" ]] && [[ $COMMENT =~ "rebuild this please" || $COMMENT =~ "update code only please" ]]; then
  # Process any hook_update_N functions and apply
  # database schema updates.
  "$DRUSH" updatedb -y --no-cache-clear
  # Rebuild caches.
  "$DRUSH" cache:rebuild
fi

# @todo Update hooks can introduce configuration changes, which can be a
# problem since we'd overwrite the configuration changes next.
# There's no easy solution, we need to run update hooks before config import.
# Others haven't found an easy solution either.
# See: https://chromatichq.com/insights/managing-drupal-configuration-automated-checks
# This means we should always deploy core and module updates separately from
# configuration changes.

if [[ $AUTO_DEPLOY == "0" ]] && [[ $COMMENT =~ "rebuild this please" ]]; then
  # Import the latest configuration.
  "$DRUSH" config:import -y
  # Rebuild caches.
  "$DRUSH" cache:rebuild
  # Process any hook_deploy_NAME functions.
  "$DRUSH" deploy -v -y
fi

if [[ $AUTO_DEPLOY == "0" ]] && [[ $COMMENT =~ "rebuild this please" || $COMMENT =~ "update code only please" ]]; then

  # Disable maintenance mode.
  "$DRUSH"  state:set system.maintenance_mode 0

fi

# Rebuild caches.
"$DRUSH" cache:rebuild

# @todo clear op cache/apcu cache
# see: https://github.com/ChromaticHQ/ansible-deploy-drupal/blob/main/handlers/main.yml

# @todo Close permissions on settings files.
if [[ $AUTO_DEPLOY == "0" ]] && [[ $COMMENT =~ "rebuild this please" || $COMMENT =~ "update code only please" ]]; then
  # Ensure default folder and settings are protected.
  chmod 0400 $(pwd)/httpdocs/sites/default/settings.php
  chmod 0400 $(pwd)/httpdocs/sites/default/civicrm.settings.php
  chmod u-w $(pwd)/httpdocs/sites/default
fi

#if [[ $AUTO_DEPLOY == "0" ]] && [[ $COMMENT =~ "test this please" ]] && [[ $ENV == DEV || $ENV == STAGING ]]; then
  # @todo Run automated tests
  # Only on staging or dev
  # php ~./web/core/scripts/run-tests.sh --all
#fi
