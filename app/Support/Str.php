<?php

declare(strict_types=1);

namespace App\Support;

final class Str
{
    public static function phone(string $value): string
    {
        return preg_replace('/\D+/', '', $value) ?? '';
    }
    public static function clean(?string $value): ?string
    {
        $v = trim((string) $value);
        return $v === '' ? null : $v;
    }
}
