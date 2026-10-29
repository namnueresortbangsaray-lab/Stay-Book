<?php

declare(strict_types=1);

namespace App\Database;

use App\Core\Config;
use RuntimeException;

final class Backup
{
    public function run(): string
    {
        $connection = new Connection('sqlite');
        $pdo = $connection->pdo();
        $folder = dirname(__DIR__, 2) . '/storage/backups';
        if (!is_dir($folder)) {
            mkdir($folder, 0770, true);
        }
        $path = $folder . '/stay-book-' . gmdate('Ymd-His') . '.sqlite';
        $pdo->exec('VACUUM INTO ' . $pdo->quote($path));
        $files = glob($folder . '/stay-book-*.sqlite') ?: [];
        rsort($files);
        foreach (array_slice($files, (int) Config::env('BACKUP_KEEP', 7)) as $old) {
            unlink($old);
        }
        if (!is_file($path)) {
            throw new RuntimeException('Backup was not created.');
        } return $path;
    }
}
