<?php

$vars = array('DB_NAME', 'DB_HOST', 'DB_USER', 'DB_PASSWORD', 'DB_CHARSET', 'DB_COLLATE');
foreach ($vars as $var) {
    define($var, getenv($var));
}

if ($_SERVER['HTTP_X_FORWARDED_PROTO'] == 'https')
    $_SERVER['HTTPS']='on';

if (isset($_SERVER['HTTP_X_FORWARDED_HOST'])) {
    $_SERVER['HTTP_HOST'] = $_SERVER['HTTP_X_FORWARDED_HOST'];
}
# $_SERVER['REQUEST_URI'] = "/blog".$_SERVER['REQUEST_URI'];

define( 'WP_SITEURL', '/');
define( 'WP_HOME', '/');

$table_prefix  = 'wp_';
if ( !defined('ABSPATH') )
        define('ABSPATH', dirname(__FILE__) . '/');

/** Sets up WordPress vars and included files. */
require_once(ABSPATH . 'wp-settings.php');
?>
