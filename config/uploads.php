<?php

declare(strict_types=1);

use App\Core\Config;

return [
    'path' => dirname(__DIR__) . '/storage/app/uploads',
    'max_bytes' => (int) Config::env('UPLOAD_MAX_BYTES', 5_242_880),
    'mimes' => ['image/jpeg' => 'jpg', 'image/png' => 'png', 'image/webp' => 'webp', 'application/pdf' => 'pdf'],
];
