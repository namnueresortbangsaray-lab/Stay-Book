<?php

declare(strict_types=1);

namespace App\Database\Dialects;

interface DialectInterface
{
    public function search(string $column, string $parameter): string;
    public function pagination(): string;
    public function upsert(string $table, array $columns, array $conflict, array $updates): string;
    public function boolean(bool $value): int|bool;
}
