<?php

declare(strict_types=1);

namespace App\Http\Requests;

use RuntimeException;

final class ValidationException extends RuntimeException
{
    /** @param array<string, string> $errors */
    public function __construct(public readonly array $errors)
    {
        parent::__construct('ข้อมูลไม่ถูกต้อง');
    }
}
