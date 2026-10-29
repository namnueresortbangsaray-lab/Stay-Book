<?php

declare(strict_types=1);

namespace App\Models;

use App\Support\Date;

final class PriceCalculator
{
    /** @return array<string, int> */
    public static function calculate(array $room, int $guests, string $from, string $to, bool $extraBed, int $petCount, int $discount, int $deposit, bool $depositPaid): array
    {
        $nights = Date::nights($from, $to);
        $extraGuests = max(0, $guests - (int) $room['base_guests']);
        $roomTotal = (int) $room['price_satang'] * $nights;
        $extraGuestTotal = (int) $room['extra_guest_fee_satang'] * $extraGuests * $nights;
        $extraBedTotal = $extraBed ? 20_000 : 0;
        $petTotal = $petCount > 0 ? 20_000 * $nights : 0;
        $gross = $roomTotal + $extraGuestTotal + $extraBedTotal + $petTotal;
        $net = max(0, $gross - $discount);
        return ['nights' => $nights, 'room_total_satang' => $roomTotal, 'extra_guest_total_satang' => $extraGuestTotal, 'extra_bed_total_satang' => $extraBedTotal, 'pet_total_satang' => $petTotal, 'gross_total_satang' => $gross, 'total_amount_satang' => $net, 'balance_due_satang' => max(0, $net - ($depositPaid ? $deposit : 0))];
    }
}
