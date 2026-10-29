<?php

declare(strict_types=1);

namespace App\Console\Commands;

interface CommandInterface
{
    public function run(array $arguments): int;
}
