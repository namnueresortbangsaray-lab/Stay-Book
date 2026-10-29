<?php

declare(strict_types=1);

$_ENV['APP_ENV'] = 'testing';
$_ENV['DB_DRIVER'] = (string) (getenv('TEST_DB_DRIVER') ?: 'sqlite');
$_ENV['SQLITE_PATH'] = dirname(__DIR__) . '/storage/database/test.sqlite';
putenv('APP_ENV=testing');
putenv('DB_DRIVER=' . $_ENV['DB_DRIVER']);
putenv('SQLITE_PATH=' . $_ENV['SQLITE_PATH']);
require dirname(__DIR__) . '/bootstrap/autoload.php';
App\Core\Config::load(dirname(__DIR__) . '/config');
