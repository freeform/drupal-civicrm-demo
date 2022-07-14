<?php

/**
 * CiviCRM Configuration File.
 */

/**
 * Copy civcrm.settings.php.template from CiviCRM core.
 * Place this snippet in civicrm.settings.php, just below "global $civicrm_root, $civicrm_setting, $civicrm_paths;"
 *
 * if (file_exists(__DIR__ . '/civicrm.settings.local.php')) {
 *   include __DIR__ . '/civicrm.settings.local.php';
 * }
 */

/**
 * CMS
 */
define('CIVICRM_UF', 'Drupal8');

/**
 * Databases
 */
define( 'CIVICRM_UF_DSN', 'mysql://drupal9:drupal9@database:3306/drupal9?new_link=true');

define('CIVICRM_DSN', 'mysql://civi:civi@civicrm:3306/civi?new_link=true');

/**
 * Site keys
 */
define( 'CIVICRM_SITE_KEY', 'RANDOM');

define('CIVICRM_CRED_KEYS', '');

define( 'CIVICRM_SIGN_KEYS', '');

/**
 * File paths and URLs
 */
$civicrm_root = '/app/vendor/civicrm/civicrm-core/';

define( 'CIVICRM_TEMPLATE_COMPILEDIR', '/app/private/civicrm/templates_c');

$site_url = 'https://EXAMPLE.lndo.site';
define('CIVICRM_UF_BASEURL', $site_url . '/');

$civicrm_paths['cms.root']['url'] = $site_url;
$civicrm_paths['cms.root']['path'] = '/app/httpdocs';
$civicrm_paths['civicrm.files']['url'] = $site_url . '/sites/default/files/civicrm';
$civicrm_paths['civicrm.files']['path'] = '/app/httpdocs/sites/default/files/civicrm';
$civicrm_paths['civicrm.private']['path'] = '/app/private/civicrm';

/**
 * URL settings
 */

// Override the Temporary Files directory.
$civicrm_setting['domain']['uploadDir'] = '[civicrm.files]/upload/' ;

// Override the custom files upload directory.
$civicrm_setting['domain']['customFileUploadDir'] = '[civicrm.files]/custom/';

// Override the images directory.
$civicrm_setting['domain']['imageUploadDir'] = '[civicrm.files]/persist/contribute/' ;

// Override the custom templates directory.
$civicrm_setting['domain']['customTemplateDir'] = '[cms.root]/civicrm_custom/custom_tpl';

// Override the Custom php path directory.
$civicrm_setting['domain']['customPHPPathDir'] = '[cms.root]/civicrm_custom/custom_php';

// Override the extensions directory.
$civicrm_setting['domain']['extensionsDir'] = '[cms.root]/civicrm_custom/extensions';

// Override the extensions resource URL
$civicrm_setting['domain']['extensionsURL'] = '[cms.root]/civicrm_custom/extensions/';

// Override the resource url
$civicrm_setting['domain']['userFrameworkResourceURL'] = '[cms.root]/libraries/civicrm/core';

// Override the Image Upload URL (System Settings > Resource URLs)
$civicrm_setting['domain']['imageUploadURL'] = '[civicrm.files]/persist/contribute';

// Disable automatic download / installation of extensions
$civicrm_setting['domain']['ext_repo_url'] = false;

// SSL
$civicrm_setting['domain']['enableSSL'] = false;
$civicrm_setting['domain']['verifySSL'] = false;

// Logging
$civicrm_setting['domain']['logging'] = 0;

// Mail
$civicrm_setting['domain']['allow_mail_from_logged_in_contact'] = 0;

// Mailer
// SMTP = 0, Sendmail = 1, Disable = 2, mail() = 3, Redirect to db = 5
$civicrm_setting['domain']['mailing_backend']['outBound_option'] = 3;

// SMTP settings
$civicrm_setting['domain']['mailing_backend']['smtpServer'] = 'smtp.sparkpostmail.com';
$civicrm_setting['domain']['mailing_backend']['smtpPort'] = 587;
$civicrm_setting['domain']['mailing_backend']['smtpAuth'] = 1;
$civicrm_setting['domain']['mailing_backend']['smtpUsername'] = 'SMTP_Injection';
$civicrm_setting['domain']['mailing_backend']['smtpPassword'] = '';

/**
 * SMARTY Compile Check:
 */
define('CIVICRM_TEMPLATE_COMPILE_CHECK', FALSE);

/**
 * Environment settings
 */

// define('CIVICRM_MAIL_LOG', '/app/private/civicrm/mail.log');
// define('CIVICRM_MAIL_LOG_AND_SEND', 1);

/**
 * Options: 'Production', 'Staging', 'Development'.
 */
$civicrm_setting['domain']['environment'] = 'Production';
