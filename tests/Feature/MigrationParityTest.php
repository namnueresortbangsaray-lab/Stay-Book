<?php

declare(strict_types=1);

namespace Tests\Feature;

use PHPUnit\Framework\TestCase;

final class MigrationParityTest extends TestCase
{
    public function testDriverFoldersHaveMatchingMigrationNamesAndTables(): void
    {
        $root = dirname(__DIR__, 2) . '/database/migrations';
        $sqlite = array_map('basename', glob($root . '/sqlite/*.sql') ?: []);
        $pgsql = array_map('basename', glob($root . '/pgsql/*.sql') ?: []);
        self::assertSame($sqlite, $pgsql);
        $extract = static function (string $driver) use ($root): array {
            $sql = implode("\n", array_map(static fn ($f) => (string) file_get_contents($f), glob($root . '/' . $driver . '/*.sql') ?: []));
            preg_match_all('/CREATE TABLE IF NOT EXISTS ([a-z_]+)/i', $sql, $matches);
            sort($matches[1]);
            return $matches[1];
        };
        self::assertSame($extract('sqlite'), $extract('pgsql'));

        $columns = static function (string $driver) use ($root): array {
            $sql = implode("\n", array_map(static fn ($file) => (string) file_get_contents($file), glob($root . '/' . $driver . '/*.sql') ?: []));
            preg_match_all('/CREATE TABLE IF NOT EXISTS ([a-z_]+)\s*\((.*?)\);/is', $sql, $tables, PREG_SET_ORDER);
            $schema = [];
            foreach ($tables as $table) {
                preg_match_all('/^\s*([a-z_]+)\s+(?!KEY|REFERENCES|CHECK|UNIQUE)/mi', $table[2], $matches);
                $schema[$table[1]] = array_values(array_unique($matches[1]));
                sort($schema[$table[1]]);
            }
            ksort($schema);
            return $schema;
        };
        self::assertSame($columns('sqlite'), $columns('pgsql'));
    }
}
