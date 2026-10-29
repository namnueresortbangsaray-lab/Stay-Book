<?php

declare(strict_types=1);

namespace App\Support;

final class Csv
{
    public static function safe(mixed $value): string
    {
        $text = (string) $value;
        if ($text !== '' && in_array($text[0], ['=', '+', '-', '@'], true)) {
            return "'" . $text;
        }
        return $text;
    }
}
