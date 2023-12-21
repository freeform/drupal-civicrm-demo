Drupal - CiviCRM Demo
=======================

A demo Drupal and CiviCRM site. Can be deployed on Tugboatqa.com.

STEPS
-----

`lando drush si --db-url=mysql://drupal10:drupal10@database:3306/drupal10 --account-pass=mom -y`

`lando cv core:uninstall --cwd="./httpdocs"`

`lando cv core:install --cwd="./httpdocs" --cms-base-url="https://dcivi.lndo.site" -m -v -K --db=mysql://drupal10:drupal10@database:3306/civicrm`
