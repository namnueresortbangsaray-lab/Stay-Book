<?php

declare(strict_types=1);

namespace Tests\Unit;

use App\Http\Requests\StayRequest;
use App\Http\Requests\ValidationException;
use PHPUnit\Framework\Attributes\DataProvider;
use PHPUnit\Framework\TestCase;

final class StayRequestTest extends TestCase
{
    #[DataProvider('invalidDates')]
    public function testRejectsInvalidOrZeroNightRanges(string $checkIn, string $checkOut): void
    {
        $this->expectException(ValidationException::class);
        StayRequest::validate(array_replace($this->validInput(), [
            'check_in_date' => $checkIn,
            'check_out_date' => $checkOut,
        ]));
    }

    public function testRejectsNegativeFinancialAmountsInsteadOfSilentlyClampingThem(): void
    {
        try {
            StayRequest::validate(array_replace($this->validInput(), ['deposit_amount' => -1, 'discount_amount' => -50]));
            self::fail('Negative money values must be rejected.');
        } catch (ValidationException $exception) {
            self::assertArrayHasKey('deposit_amount', $exception->errors);
            self::assertArrayHasKey('discount_amount', $exception->errors);
        }
    }

    /** @return iterable<string, array{string, string}> */
    public static function invalidDates(): iterable
    {
        yield 'same day' => ['2030-01-10', '2030-01-10'];
        yield 'checkout before checkin' => ['2030-01-10', '2030-01-09'];
        yield 'invalid leap day' => ['2030-02-29', '2030-03-01'];
    }

    /** @return array<string, mixed> */
    private function validInput(): array
    {
        return [
            'guest_name' => 'ผู้เข้าพัก ทดสอบ',
            'phone' => '0812345678',
            'room_id' => 'room-id',
            'check_in_date' => '2030-01-10',
            'check_out_date' => '2030-01-12',
            'guests' => 2,
            'status' => 0,
            'pet_count' => 0,
            'deposit_amount' => 0,
            'discount_amount' => 0,
        ];
    }
}
