<?php

declare(strict_types=1);

namespace Tests\Unit;

use App\Models\PriceCalculator;
use PHPUnit\Framework\TestCase;

final class PriceCalculatorTest extends TestCase
{
    public function testPricingMatchesFlutterRules(): void
    {
        $room = ['price_satang' => 50_000, 'base_guests' => 2, 'extra_guest_fee_satang' => 10_000];
        $price = PriceCalculator::calculate($room, 3, '2026-08-18', '2026-08-20', true, 0, 0, 0, false);
        self::assertSame(2, $price['nights']);
        self::assertSame(140_000, $price['total_amount_satang']);
    }

    public function testPetDiscountAndPaidDeposit(): void
    {
        $room = ['price_satang' => 50_000, 'base_guests' => 2, 'extra_guest_fee_satang' => 10_000];
        $price = PriceCalculator::calculate($room, 2, '2026-08-18', '2026-08-20', true, 2, 30_000, 50_000, true);
        self::assertSame(160_000, $price['gross_total_satang']);
        self::assertSame(130_000, $price['total_amount_satang']);
        self::assertSame(80_000, $price['balance_due_satang']);
    }

    public function testUnpaidDepositDoesNotReduceBalance(): void
    {
        $room = ['price_satang' => 50_000, 'base_guests' => 2, 'extra_guest_fee_satang' => 10_000];
        $price = PriceCalculator::calculate($room, 2, '2026-08-18', '2026-08-19', false, 0, 0, 30_000, false);
        self::assertSame(50_000, $price['balance_due_satang']);
    }
}
