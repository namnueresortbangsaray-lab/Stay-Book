<?php

declare(strict_types=1);

use App\Core\Config;

return [
    'path' => dirname(__DIR__) . '/storage/sessions',
    'lifetime' => (int) Config::env('SESSION_LIFETIME', 120) * 60,
    'secure' => Config::env('APP_ENV', 'production') === 'production',
];
