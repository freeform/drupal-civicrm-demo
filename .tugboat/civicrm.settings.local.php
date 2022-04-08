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
define( 'CIVICRM_UF_DSN', 'mysql://tugboat:tugboat@drupal9:3306/tugboat?new_link=true');

define('CIVICRM_DSN', 'mysql://tugboat:tugboat@civicrm:3306/tugboat?new_link=true');

/**
 * Site keys
 */
define( 'CIVICRM_SITE_KEY', 'NIzZQCPJLoYCaVLwiqEW17MSHcnyIo957XwQnjq7Xc');

define('CIVICRM_CRED_KEYS', 'aes-cbc:hkdf-sha256:sZ0PQwlzdj93Pjm0iaC3m5Ao7OWwxA1H1sNWiE1X8cgj61uA');

define( 'CIVICRM_SIGN_KEYS', 'jwt-hs256:hkdf-sha256:wSdxWNA6iKto4eL0RiNZtvckTL15AsOVdg0FGWJKRiLqhSqztyg');

/**
 * File paths and URLs
 */
$civicrm_root = getenv('TUGBOAT_ROOT') . '/vendor/civicrm/civicrm-core/';

define( 'CIVICRM_TEMPLATE_COMPILEDIR', getenv('TUGBOAT_ROOT') . '/private/civicrm/templates_c');

$civicrm_paths['civicrm.files']['url'] = getenv('TUGBOAT_DEFAULT_SERVICE_URL') . 'sites/default/files/civicrm';
$civicrm_paths['civicrm.files']['path'] = getenv('TUGBOAT_ROOT') . '/httpdocs/sites/default/files/civicrm';

/**
 * URL settings
 */
define('CIVICRM_UF_BASEURL', getenv('TUGBOAT_DEFAULT_SERVICE_URL'));

// Override the Temporary Files directory.
$civicrm_setting['domain']['uploadDir'] = getenv('TUGBOAT_ROOT') . '/httpdocs/sites/default/files/civicrm/upload/' ;

// Override the custom files upload directory.
$civicrm_setting['domain']['customFileUploadDir'] = getenv('TUGBOAT_ROOT') . '/httpdocs/sites/default/files/civicrm/custom/';

// Override the images directory.
$civicrm_setting['domain']['imageUploadDir'] = getenv('TUGBOAT_ROOT') . '/httpdocs/sites/default/files/civicrm/persist/contribute/' ;

// Override the custom templates directory.
$civicrm_setting['domain']['customTemplateDir'] = getenv('TUGBOAT_ROOT') . '/httpdocs/civicrm_custom/custom_tpl';

// Override the Custom php path directory.
$civicrm_setting['domain']['customPHPPathDir'] = getenv('TUGBOAT_ROOT') . '/httpdocs/civicrm_custom/custom_php';

// Override the extensions directory.
$civicrm_setting['domain']['extensionsDir'] = getenv('TUGBOAT_ROOT') . '/httpdocs/civicrm_custom/extensions';

// Override the extensions resource URL
$civicrm_setting['domain']['extensionsURL'] = CIVICRM_UF_BASEURL . 'civicrm_custom/extensions/';

// Override the resource url
$civicrm_setting['domain']['userFrameworkResourceURL'] = CIVICRM_UF_BASEURL . 'libraries/civicrm/core';

// Override the Image Upload URL (System Settings > Resource URLs)
$civicrm_setting['domain']['imageUploadURL'] = CIVICRM_UF_BASEURL . 'sites/default/files/civicrm/persist/contribute';

// Disable automatic download / installation of extensions
$civicrm_setting['domain']['ext_repo_url'] = false;

// SSL
$civicrm_setting['domain']['enableSSL'] = false;
$civicrm_setting['domain']['verifySSL'] = false;

// Logging
$civicrm_setting['domain']['logging'] = 0;

/**
 * SMARTY Compile Check:
 */
define( 'CIVICRM_TEMPLATE_COMPILE_CHECK', FALSE);

/**
 * DB DSN: mysql or mysqli
 */
define('DB_DSN_MODE', 'auto');

/**
 * Environment settings
 */

//  define( 'CIVICRM_MAIL_LOG', getenv('TUGBOAT_ROOT') . '/private/civicrm/mail.log');
//  define( 'CIVICRM_MAIL_LOG_AND_SEND', 1);

/**
 * Options: 'Production', 'Staging', 'Development'.
 */
$civicrm_setting['domain']['environment'] = 'Production';
