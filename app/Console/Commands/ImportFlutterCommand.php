<?php

declare(strict_types=1);

namespace App\Console\Commands;

final class ImportFlutterCommand implements CommandInterface
{
    public function run(array $arguments): int
    {
        fwrite(
            STDERR,
            "No legacy data source was found. The original mobile app stores stay_book.db in its private device " .
            "sandbox, and this repository contains no database, Hive box, or JSON export to import. " .
            "Export the device database before attempting a data migration.\n"
        );

        return 2;
    }
}
