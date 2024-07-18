Drupal - CiviCRM Demo
=======================

A demo Drupal and CiviCRM site. Can be deployed on Tugboatqa.com.

Steps
-----

1. Fork this repo.
2. Create an account on https://www.tugboatqa.com by connecting with a github account. Can be used for free with a size limit.
3. Under My Projects create a new project and select github, your namespace and this repo.
4. Select the Branch tab, `main` branch and click `Build Preview`.
5. The first time the build process takes some time, but this gets cached.
6. If the build is successful. Click on the `Preview` button which opens the site.
7. Login with `admin` and `123somethingpencil`.

Start in Lando local dev
------------------------

Can also test this in [Lando](https://lando.dev).

`lando drush si --db-url=mysql://drupal10:drupal10@database:3306/drupal10 --account-pass=mom -y`

`lando cv core:uninstall --cwd="./httpdocs"`

`lando cv core:install --cwd="./httpdocs" --cms-base-url="https://dcivi.lndo.site" -m -v -K --db=mysql://drupal10:drupal10@database:3306/civicrm`

Upgrades
--------

`composer outdate "drupal/*"`
`composer update "drupal/core-*" -W`

<https://docs.civicrm.org/sysadmin/en/latest/upgrade/drupal8/>

`composer update civicrm/civicrm-{core,packages,drupal-8} --with-all-dependencies`
`cv --cwd="httpdocs" upgrade:db`
