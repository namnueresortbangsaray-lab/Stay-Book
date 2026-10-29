<?php

declare(strict_types=1);

namespace App\Console;

use App\Console\Commands\BackupCommand;
use App\Console\Commands\ImportFlutterCommand;
use App\Console\Commands\MigrateCommand;
use App\Console\Commands\SeedCommand;
use App\Console\Commands\TransferCommand;
use App\Console\Commands\UserCreateCommand;

final class Kernel
{
    public function run(array $argv): int
    {
        $name = $argv[1] ?? 'help';
        $args = array_slice($argv, 2);
        $commands = ['migrate' => new MigrateCommand(),'seed' => new SeedCommand(),'user:create' => new UserCreateCommand(),'db:backup' => new BackupCommand(),'db:transfer' => new TransferCommand(),'import:flutter' => new ImportFlutterCommand()];
        if (!isset($commands[$name])) {
            echo "Stay Book CLI\n  migrate\n  seed\n  user:create --name=... --email=... --password=... [--role=...]\n  db:backup\n  db:transfer --from=sqlite --to=pgsql [--truncate] [--dry-run]\n  import:flutter\n";
            return $name === 'help' ? 0 : 1;
        }
        return $commands[$name]->run($args);
    }
}
