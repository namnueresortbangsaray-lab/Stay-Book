<?php

declare(strict_types=1);

if (PHP_SAPI === 'cli-server') {
    $path = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH);
    if (is_string($path) && is_file(__DIR__ . $path)) {
        return false;
    }
}

$application = require dirname(__DIR__) . '/bootstrap/app.php';
$application->run();
