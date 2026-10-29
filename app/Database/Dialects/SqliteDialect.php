<?php

declare(strict_types=1);

namespace App\Database\Dialects;

final class SqliteDialect implements DialectInterface
{
    public function search(string $column, string $parameter): string
    {
        return "LOWER({$column}) LIKE LOWER({$parameter})";
    }
    public function pagination(): string
    {
        return ' LIMIT :limit OFFSET :offset';
    }
    public function boolean(bool $value): int
    {
        return $value ? 1 : 0;
    }
    public function upsert(string $table, array $columns, array $conflict, array $updates): string
    {
        return sprintf('INSERT INTO %s (%s) VALUES (%s) ON CONFLICT (%s) DO UPDATE SET %s', $table, implode(',', $columns), implode(',', array_map(static fn ($c) => ':' . $c, $columns)), implode(',', $conflict), implode(',', array_map(static fn ($c) => $c . '=excluded.' . $c, $updates)));
    }
}
