<?php

declare(strict_types=1);

namespace App\Console\Commands;

use App\Database\Connection;
use App\Database\Migrator;

final class MigrateCommand implements CommandInterface
{
    public function run(array $arguments): int
    {
        $done = (new Migrator(new Connection()))->migrate();
        echo $done ? 'Applied: '.implode(', ', $done).PHP_EOL : 'Database is current.'.PHP_EOL;
        return 0;
    }
}
