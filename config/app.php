<?php

declare(strict_types=1);

use App\Core\Config;

return [
    'name' => Config::env('APP_NAME', 'Stay Book'),
    'env' => Config::env('APP_ENV', 'production'),
    'debug' => Config::env('APP_DEBUG', false),
    'key' => Config::env('APP_KEY', ''),
    'url' => Config::env('APP_URL', 'http://localhost:8080'),
    'timezone' => Config::env('APP_TIMEZONE', 'Asia/Bangkok'),
];
