#!/bin/bash

#
# PoormansDeploy Tool - Drupal 9
#
# Version 0.2
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
# Beanstalk deployment commands:
# First ensure we can run this script.
# chmod +x %REMOTE_PATH%/.poormansdeploy/*
# %REMOTE_PATH%/.poormansdeploy/main.sh %AUTO?% %TIMESTAMP_UTC% %REVISION% %REMOTE_PATH% "%COMMENT%" ENV
#
# ENV: can be LIVE, DEV, STAGING. Anything other than DEV, STAGING is assumed to
#      be LIVE for safety.

# Build strategy
#
# Since build steps could potentially fail, leaving a live site broken, deployments
# are first done to a releases directory.
# For example, /var/www/vhosts/example.ca/www/releases/new
#
# The structure in the site directory is like:
# settings.local.php
# civicrm.settings.local.php
# files
# private
# keys
# app (symlink to releases/current)
# app/httpdocs (webroot)
# releases/[new,current,old]
#
# We create symlinks from the settings and file directories in the site root
# to the current release with each deployment. Then rotate the releases and
# re-symlink the app to the current release.
#
# On the first deployment, we need to manually create the local settings files and
# directories in the site root. They are not in the repo and outside of the webroot.
#
# This strategy is adapted from:
# https://docs.gitlab.com/ee/ci/examples/laravel_with_gitlab_and_envoy/
# also see https://laracasts.com/discuss/channels/general-discussion/continuous-deployment-how-to-composer-install-instead-of-on-production-server-proscons

set -o errexit

AUTO_DEPLOY=$1
TIMESTAMP=$2
REVISION=$3

# New build
REMOTE_PATH=$4

COMMENT=$5
ENV=$6

# Site root
cd ../..

# SITE example: /var/www/vhosts/example.ca/www
SITE=$(pwd)
RELEASES_PATH="$SITE/releases"
WEB_DIR="$SITE/app/httpdocs"
DRUSH="$SITE/app/vendor/bin/drush"

# Fail if non-exported configuration changes on current site.
if [[ $AUTO_DEPLOY == "0" ]] && [[ $COMMENT =~ "rebuild this please" ]]; then
  # Identify Drupal configuration changes in core or contrib updates, or
  # manual configuration changes on this site that were not exported and
  # not committed to the sync directory.
  cd "$RELEASES_PATH/current"

  echo "Checking the live site for configuration changes not committed."

  OUTPUT=$("$DRUSH" config:export -y 2>&1 > /dev/null)
  echo "$OUTPUT"
  if [[ $OUTPUT =~ "active configuration is identical" ]]; then
    echo "Configuration matches the sync directory so okay to rebuild."
  else
    echo "Error: there are configuration changes in this environment that are not yet in the repo. Quitting to prevent them being overwritten."
    exit 1
  fi
fi

# Build the new release

echo "Build steps: Composer, etc."

cd "$REMOTE_PATH"

# Ensure we can write to default folder.
chmod u+w "$REMOTE_PATH/httpdocs/sites/default"

# Install any updated or new packages.
# CiviCRM requires dev packages
echo "Install any updated or new Composer packages."
composer config extra.compile-mode all
composer install --no-interaction

# Could also include any other build steps here (SASS, NPM, etc).

# If that went well, we deploy fully

echo "Deploying the code changes by updating symlinks."

cd $RELEASES_PATH

# Move the releases down the line.
rm -r "$RELEASES_PATH/old"
mv "$RELEASES_PATH/current" "$RELEASES_PATH/old"
mv "$RELEASES_PATH/new" "$RELEASES_PATH/current"

# Now do rest of steps in current site.
cd "$RELEASES_PATH/current"

# Create the symlinks in current to settings and files.
ln -nfs "$SITE/files" "$RELEASES_PATH/current/httpdocs/sites/default/files"
ln -nfs "$SITE/settings.local.php" "$RELEASES_PATH/current/httpdocs/sites/default/settings.local.php"
ln -nfs "$SITE/civicrm.settings.local.php" "$RELEASES_PATH/current/httpdocs/sites/default/civicrm.settings.local.php"
ln -nfs "$SITE/private" "$RELEASES_PATH/current/private"
ln -nfs "$SITE/keys" "$RELEASES_PATH/current/keys"

# Then symlink current release to app directory.
cd $SITE && ln -nfs "$RELEASES_PATH/current" app

echo "Output information about the site to aid in debugging failed deployments."
cd "$SITE/app"
"$DRUSH" core:status

if [[ $AUTO_DEPLOY == "0" ]] && [[ $COMMENT =~ "rebuild civicrm localise please |" ]]; then
  echo "Rebuild CiviCRM localisation files."
  cd "$SITE/app" && ./.poormansdeploy/civicrm-localise.sh "$COMMENT"
fi

if [[ $AUTO_DEPLOY == "0" ]] && [[ $COMMENT =~ "rebuild this please" || $COMMENT =~ "update code only please" ]]; then
  echo "Backdup the Drupal database."
  cd "$SITE/app"
  "$DRUSH" sql:dump --gzip --result-file=auto

  # Put the site into maintenance mode to prevent conflicts
  # from occurring during database updates.
  echo "Set maintenance mode."
  "$DRUSH" --root="$WEB_DIR" state:set system.maintenance_mode 1
fi

# If it's a git repo pull the latest code.
# Otherwise ignore - SFTP mode will deploy files.
if git rev-parse --git-dir > /dev/null 2>&1; then
  echo "Checkout the referenced revision with git."
  cd "$SITE/app"
  git checkout master
  git pull origin master
  git checkout $REVISION
fi

# if [[ $AUTO_DEPLOY == "0" ]] && [[ $COMMENT =~ "refresh civicrm from live please |" ]] && [[ $ENV == DEV || $ENV == STAGING ]]; then
#   echo "Refresh the CiviCRM database from live."
#   cd "$SITE/app"
#   ./.poormansdeploy/civicrm-refresh.sh "$COMMENT"
# fi

if [[ $AUTO_DEPLOY == "0" ]] && [[ $COMMENT =~ "rebuild this please" || $COMMENT =~ "update code only please" ]]; then
  echo "Process update hooks and update Drupal database."
  cd "$SITE/app"
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
  echo "Attempt to import Drupal configuration from the repo."
  cd "$SITE/app"
  "$DRUSH" config:import -y
  # Rebuild caches.
  "$DRUSH" cache:rebuild
  # Process any hook_deploy_NAME functions.
  echo "Process any deploy hooks."
  "$DRUSH" deploy -v -y
fi

if [[ $AUTO_DEPLOY == "0" ]] && [[ $COMMENT =~ "rebuild this please" || $COMMENT =~ "update code only please" ]]; then
  echo "Disable maintenance mode."
  cd "$SITE/app"
  "$DRUSH"  state:set system.maintenance_mode 0

fi

# Rebuild caches.
cd "$SITE/app"
"$DRUSH" cache:rebuild

# @todo clear op cache/apcu cache
# see: https://github.com/ChromaticHQ/ansible-deploy-drupal/blob/main/handlers/main.yml

# @todo Close permissions on settings files.
if [[ $AUTO_DEPLOY == "0" ]] && [[ $COMMENT =~ "rebuild this please" || $COMMENT =~ "update code only please" ]]; then
  echo "Ensure default folder and settings are protected."
  chmod 0400 "$SITE/app/httpdocs/sites/default/settings.php"
  chmod 0400 "$SITE/app/httpdocs/sites/default/civicrm.settings.php"
  chmod u-w "$SITE/app/httpdocs/sites/default"
fi

#if [[ $AUTO_DEPLOY == "0" ]] && [[ $COMMENT =~ "test this please" ]] && [[ $ENV == DEV || $ENV == STAGING ]]; then
  # echo "Run automated tests."
  # Only on staging or dev
  # cd "$SITE/app"
  # php ~./httpdocs/core/scripts/run-tests.sh --all
#fi

echo "Copy files to deployment directory so don't need to deploy all files each time."
cp -r "$RELEASES_PATH/current" "$RELEASES_PATH/new"

echo "Remove symbolic links from deployment to be safe."
cd "$RELEASES_PATH/new"

unlink "$RELEASES_PATH/new/httpdocs/sites/default/files"
unlink "$RELEASES_PATH/new/httpdocs/sites/default/settings.local.php"
unlink "$RELEASES_PATH/new/httpdocs/sites/default/civicrm.settings.local.php"
unlink "$RELEASES_PATH/new/private"
unlink "$RELEASES_PATH/new/keys"
