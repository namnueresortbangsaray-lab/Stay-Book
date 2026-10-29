<?php

declare(strict_types=1);

namespace App\Database;

use PDO;
use RuntimeException;

final class Migrator
{
    public function __construct(private readonly Connection $connection)
    {
    }

    /** @return list<string> */
    public function migrate(): array
    {
        $pdo = $this->connection->pdo();
        $type = $this->connection->driver() === 'pgsql' ? 'text' : 'TEXT';
        $pdo->exec("CREATE TABLE IF NOT EXISTS schema_migrations (version {$type} PRIMARY KEY, applied_at {$type} NOT NULL)");
        $folder = dirname(__DIR__, 2) . '/database/migrations/' . $this->connection->driver();
        $files = glob($folder . '/*.sql') ?: [];
        sort($files);
        $applied = [];
        foreach ($files as $file) {
            $version = basename($file);
            $check = $pdo->prepare('SELECT COUNT(*) FROM schema_migrations WHERE version = :version');
            $check->execute(['version' => $version]);
            if ((int) $check->fetchColumn() > 0) {
                continue;
            }
            $sql = file_get_contents($file);
            if ($sql === false) {
                throw new RuntimeException("Cannot read migration {$file}");
            }
            $pdo->beginTransaction();
            try {
                $pdo->exec($sql);
                $insert = $pdo->prepare('INSERT INTO schema_migrations(version, applied_at) VALUES(:version,:at)');
                $insert->execute(['version' => $version, 'at' => gmdate('c')]);
                $pdo->commit();
                $applied[] = $version;
            } catch (\Throwable $e) {
                if ($pdo->inTransaction()) {
                    $pdo->rollBack();
                }
                throw $e;
            }
        }
        return $applied;
    }
}
