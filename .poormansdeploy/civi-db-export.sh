#!/usr/bin/env php
<?php

/**
 * Export CiviCRM database.
 *
 * --sitepath (Path to the webroot of the site. Either full path or with tilde:
 *    E.g.: `~/www/httpdocs/`.)
 * --destination (Include path and filename. Filename should
 *   include sql.gz at the end. E.g. `~/drush-backups/civi-dump.sql.gz`)
 */

# Parse provided options.
while ($param = array_shift($_SERVER['argv'])) {
  if (strpos($param, '--') === 0) {
    $param = substr($param, 2);
    if (strpos($param, '=')) {
      list($key, $value) = explode('=', $param);
      $options[$key] = $value;
    }
    else {
      $options[$param] = array_shift($_SERVER['argv']);
    }
  }
  else {
    $arguments[] = $param;
  }
}

$home = $_SERVER['HOME'] . '/';

$destination = $home . 'drush-backups/civi_dump-' . date('Ymd') . '.sql.gz';
if (!empty($options['destination'])) {
  $destination = preg_filter('/^~\//', $home, $options['destination']);
}

# Make sure in right directory.
$sitepath = $home . 'www/httpdocs/';
if (!empty($options['sitepath'])) {
  $sitepath = preg_filter('/^~\//', $home, $options['sitepath']);
}
else {
  echo "No site path provided.";
  exit;
}

chdir($sitepath);

# Fetch CiviCRM DB credentials from cv.
$vars = shell_exec('cv vars:show');
$vars = json_decode($vars);

if (is_null($vars)) {
  echo "Unable to get CiviCRM database credentials." . PHP_EOL;
  return;
}

$db_args = '';
if (!empty($vars->CIVI_DB_NAME)) {
  $port = !empty($vars->CIVI_DB_PORT) ? $vars->CIVI_DB_PORT : '3306';
  $db_args = '-h ' . $vars->CIVI_DB_HOST . ' -u ' . $vars->CIVI_DB_USER . ' -p' . $vars->CIVI_DB_PASS . ' -P ' . $port . ' ' . $vars->CIVI_DB_NAME;
}
else if (!empty($vars->CIVI_DB_DSN) && empty($vars->CIVI_DB_NAME)) {
  $parts = explode(':', $vars->CIVI_DB_DSN);
  $user = substr($parts[1], 2);
  list($pass, $host) = explode('@', $parts[2]);
  list($port, $db_name) = explode('/', $parts[3]);
  $db_name = explode('?', $db_name)[0];
  $db_args .= '-h ' . $host . ' -u ' . $user . ' -p' . $pass . ' -P ' . $port . ' ' . $db_name;
}

$output = shell_exec('mysqldump ' . $db_args . ' | gzip > civi_tmp' . date('Ymd') . '.sql.gz');

$output = shell_exec('gunzip -c civi_tmp' . date('Ymd') . '.sql.gz | sed -e "s/DEFINER=[^ ]* / /" | gzip > civi_nodefiner-' . date('Ymd') . '.sql.gz' );

$output = shell_exec('unlink civi_tmp' . date('Ymd') . '.sql.gz');
$output = shell_exec('mv civi_nodefiner-' . date('Ymd') . '.sql.gz ' . $destination);

echo "Civi database dump has been created at $destination and definer removed." . PHP_EOL;
