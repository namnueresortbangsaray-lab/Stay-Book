<?php

declare(strict_types=1);

namespace App\Console\Commands;

use App\Database\Backup;

final class BackupCommand implements CommandInterface
{
    public function run(array $arguments): int
    {
        echo (new Backup())->run().PHP_EOL;
        return 0;
    }
}
