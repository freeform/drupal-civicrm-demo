#!/usr/bin/env php
<?php

/**
 * Import CiviCRM database.
 *
 * --file=filename.sql.gz (Must be gzip format)
 * --no-wipe (Optional. By default all tables will be dropped.)
 */

# Make sure in right directory.
chdir(__DIR__);

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

if (!isset($options['file'])) {
  echo "Missing the file to import" . PHP_EOL;
  exit;
}

# toggle wipe mode
$wipe = TRUE;
if (array_key_exists('no-wipe', $options)) {
  $wipe = FALSE;
}

# Make sure in right directory.
if (!empty($options['sitepath'])) {
  $sitepath = $options['sitepath'];
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

if (!$wipe) {
  echo "Not wiping the database before importing." . PHP_EOL;
}

# Wipe the database if set
if ($wipe) {
  echo "Emptying database: {$vars->CIVI_DB_NAME}... " . PHP_EOL;
  echo "Set the --no-wipe flag to avoid this step!" . PHP_EOL;

  $mysqli = new mysqli($vars->CIVI_DB_HOST, $vars->CIVI_DB_USER, $vars->CIVI_DB_PASS);
  if ($mysqli->connect_error) {
    die("Connection failed: " . $mysqli->connect_error);
  }

  $mysqli->select_db($vars->CIVI_DB_NAME);

  if ($statement = $mysqli->prepare("SHOW TABLES FROM `{$vars->CIVI_DB_NAME}`")) {
    $statement->execute();
    $statement->bind_result($table_name);

    while ($statement->fetch()) {
      $table_names[] = $table_name;
    }
    $statement->close();

    $mysqli->query("USE `{$vars->CIVI_DB_NAME}`;");
    $mysqli->query("SET FOREIGN_KEY_CHECKS = 0;");
    foreach ($table_names as $name) {
      echo "Dropping $name" . PHP_EOL;
      $drop_query = "DROP VIEW IF EXISTS `{$name}`;\n";
      if (!$mysqli->query($drop_query)) {
        printf("Error message: %s\n", $mysqli->error);
      }

      $drop_query = "DROP TABLE IF EXISTS `{$name}`;\n";
      if (!$mysqli->query($drop_query)) {
        printf("Error message: %s\n", $mysqli->error);
      }
    }
  }

  $mysqli->close();
}

# Import
$input_command = 'gunzip < ' . $options['file'] . ' | mysql ' . $vars->CIVI_DB_ARGS;

$output = shell_exec($input_command);

echo "Civi database has been imported." . PHP_EOL;
