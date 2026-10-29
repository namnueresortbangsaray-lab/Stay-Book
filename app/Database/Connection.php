<?php

declare(strict_types=1);

namespace App\Database;

use App\Core\Config;
use App\Database\Dialects\DialectInterface;
use App\Database\Dialects\PgsqlDialect;
use App\Database\Dialects\SqliteDialect;
use PDO;
use RuntimeException;

final class Connection
{
    private ?PDO $pdo = null;

    public function __construct(private readonly ?string $driverOverride = null)
    {
    }

    public function driver(): string
    {
        $driver = $this->driverOverride ?? (string) Config::get('database.driver', 'sqlite');
        if (!in_array($driver, ['sqlite', 'pgsql'], true)) {
            throw new RuntimeException('DB_DRIVER must be sqlite or pgsql.');
        }
        return $driver;
    }

    public function pdo(): PDO
    {
        if ($this->pdo !== null) {
            return $this->pdo;
        }
        if ($this->driver() === 'sqlite') {
            $path = (string) Config::get('database.sqlite.path');
            if (!is_dir(dirname($path))) {
                mkdir(dirname($path), 0770, true);
            }
            $this->pdo = new PDO('sqlite:' . $path);
            $this->configure();
            $this->pdo->exec('PRAGMA foreign_keys=ON');
            $this->pdo->exec('PRAGMA journal_mode=WAL');
            $this->pdo->exec('PRAGMA busy_timeout=5000');
            return $this->pdo;
        }
        $c = Config::get('database.pgsql');
        if (!is_array($c)) {
            throw new RuntimeException('PostgreSQL configuration missing.');
        }
        $dsn = sprintf('pgsql:host=%s;port=%d;dbname=%s;sslmode=%s', $c['host'], $c['port'], $c['database'], $c['sslmode']);
        $this->pdo = new PDO($dsn, (string) $c['user'], (string) $c['password'], [PDO::ATTR_EMULATE_PREPARES => (bool) $c['emulate_prepares'] || (int) $c['port'] === 6543]);
        $this->configure();
        return $this->pdo;
    }

    public function dialect(): DialectInterface
    {
        return $this->driver() === 'pgsql' ? new PgsqlDialect() : new SqliteDialect();
    }

    private function configure(): void
    {
        $this->pdo?->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        $this->pdo?->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
        $this->pdo?->setAttribute(PDO::ATTR_STRINGIFY_FETCHES, false);
    }
}
