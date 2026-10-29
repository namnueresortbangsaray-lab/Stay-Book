<?php

declare(strict_types=1);

namespace App\Support;

use DateTimeImmutable;
use DateTimeZone;

final class Date
{
    public static function now(): string
    {
        return gmdate('c');
    }
    public static function nights(string $from, string $to): int
    {
        return max(1, (new DateTimeImmutable($from))->diff(new DateTimeImmutable($to))->days ?: 0);
    }
    public static function local(string $utc, string $format = 'd/m/Y H:i'): string
    {
        return (new DateTimeImmutable($utc))->setTimezone(new DateTimeZone('Asia/Bangkok'))->format($format);
    }
}
