<?php

declare(strict_types=1);

namespace Tests\Unit;

use App\Support\Csv;
use PHPUnit\Framework\TestCase;

final class CsvTest extends TestCase
{
    public function testEscapesSpreadsheetFormulaPrefixes(): void
    {
        self::assertSame("'=SUM(1,1)", Csv::safe('=SUM(1,1)'));
        self::assertSame("'+441234", Csv::safe('+441234'));
        self::assertSame('สมชาย', Csv::safe('สมชาย'));
    }
}
