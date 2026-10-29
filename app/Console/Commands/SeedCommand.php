<?php

declare(strict_types=1);

namespace App\Console\Commands;

use App\Database\Connection;
use App\Database\Seeder;

final class SeedCommand implements CommandInterface
{
    public function run(array $arguments): int
    {
        (new Seeder(new Connection()))->seed();
        echo "Seed complete.\n";
        return 0;
    }
}
