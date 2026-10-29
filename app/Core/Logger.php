<?php

declare(strict_types=1);

namespace App\Core;

use Throwable;

final class Logger
{
    public static function error(Throwable $error): void
    {
        $path = (string) Config::get('logging.path');
        if (!is_dir(dirname($path))) {
            mkdir(dirname($path), 0770, true);
        }
        error_log(sprintf("[%s] %s in %s:%d\n", gmdate('c'), $error->getMessage(), $error->getFile(), $error->getLine()), 3, $path);
    }
}
