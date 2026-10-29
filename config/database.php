<?php

declare(strict_types=1);

use App\Core\Config;

return [
    'driver' => Config::env('DB_DRIVER', 'sqlite'),
    'sqlite' => ['path' => Config::env('SQLITE_PATH', dirname(__DIR__) . '/storage/database/stay_book.sqlite')],
    'pgsql' => [
        'host' => Config::env('SUPABASE_DB_HOST', 'postgres'),
        'port' => (int) Config::env('SUPABASE_DB_PORT', 5432),
        'database' => Config::env('SUPABASE_DB_NAME', 'postgres'),
        'user' => Config::env('SUPABASE_DB_USER', 'postgres'),
        'password' => Config::env('SUPABASE_DB_PASSWORD', ''),
        'sslmode' => Config::env('PGSQL_SSLMODE', 'require'),
        'emulate_prepares' => Config::env('PGSQL_EMULATE_PREPARES', false),
    ],
];
