<?php

declare(strict_types=1);

namespace App\Database\Dialects;

final class PgsqlDialect implements DialectInterface
{
    public function search(string $column, string $parameter): string
    {
        return "{$column} ILIKE {$parameter}";
    }
    public function pagination(): string
    {
        return ' LIMIT :limit OFFSET :offset';
    }
    public function boolean(bool $value): bool
    {
        return $value;
    }
    public function upsert(string $table, array $columns, array $conflict, array $updates): string
    {
        return sprintf('INSERT INTO %s (%s) VALUES (%s) ON CONFLICT (%s) DO UPDATE SET %s', $table, implode(',', $columns), implode(',', array_map(static fn ($c) => ':' . $c, $columns)), implode(',', $conflict), implode(',', array_map(static fn ($c) => $c . '=EXCLUDED.' . $c, $updates)));
    }
}
