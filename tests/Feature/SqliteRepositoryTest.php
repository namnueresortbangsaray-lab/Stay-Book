<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Database\Connection;
use App\Database\Migrator;
use App\Database\Seeder;
use App\Repositories\Database\ResortRepository;
use PHPUnit\Framework\TestCase;

final class SqliteRepositoryTest extends TestCase
{
    public function testMigrationSeedAndOverlapQuery(): void
    {
        if ((string) \App\Core\Config::get('database.driver') !== 'sqlite') {
            self::markTestSkipped('SQLite-only test.');
        }
        $path = (string) \App\Core\Config::get('database.sqlite.path');
        foreach ([$path, $path . '-wal', $path . '-shm'] as $file) {
            if (is_file($file)) {
                unlink($file);
            }
        }
        $connection = new Connection('sqlite');
        (new Migrator($connection))->migrate();
        (new Seeder($connection))->seed();
        $repository = new ResortRepository($connection);
        self::assertNotEmpty($repository->rooms());
        self::assertNotNull($repository->findUserByEmail('admin@staybook.local'));
        self::assertFalse($repository->hasOverlap($repository->rooms()[0]['id'], '2026-01-01', '2026-01-02'));
    }
}
