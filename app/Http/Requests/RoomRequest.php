<?php

declare(strict_types=1);

namespace App\Http\Requests;

final class RoomRequest
{
    public static function validate(array $input): array
    {
        $errors = [];
        foreach (['name' => 'ชื่อห้อง', 'zone' => 'โซน', 'type' => 'ประเภทห้อง'] as $key => $label) {
            if (trim((string) ($input[$key] ?? '')) === '') {
                $errors[$key] = "กรุณากรอก{$label}";
            }
        }
        $price = self::money($input['price'] ?? null);
        $extraGuestFee = self::money($input['extra_guest_fee'] ?? 0);
        $base = (int) ($input['base_guests'] ?? 0);
        $max = (int) ($input['max_guests'] ?? 0);
        if ($price < 1) {
            $errors['price'] = 'ราคาต้องมากกว่า 0';
        }
        if (!self::validMoney($input['price'] ?? null, false)) {
            $errors['price'] = 'ราคาต้องเป็นตัวเลขที่มากกว่า 0';
        }
        if (!self::validMoney($input['extra_guest_fee'] ?? 0)) {
            $errors['extra_guest_fee'] = 'ค่าแขกเสริมต้องเป็นตัวเลขที่ไม่ติดลบ';
        }
        if ($base < 1) {
            $errors['base_guests'] = 'จำนวนคนพื้นฐานต้องอย่างน้อย 1';
        }
        if ($max < $base) {
            $errors['max_guests'] = 'จำนวนคนสูงสุดต้องไม่น้อยกว่าจำนวนคนพื้นฐาน';
        }
        if ($errors) {
            throw new ValidationException($errors);
        }
        return ['name' => trim((string) $input['name']), 'zone' => trim((string) $input['zone']), 'type' => trim((string) $input['type']), 'price_satang' => $price, 'base_guests' => $base, 'max_guests' => $max, 'extra_guest_fee_satang' => $extraGuestFee, 'sort_order' => max(0, (int) ($input['sort_order'] ?? 0)), 'is_pet_friendly' => self::bool($input['is_pet_friendly'] ?? false)];
    }

    public static function money(mixed $value): int
    {
        return (int) round(max(0, (float) $value) * 100);
    }

    public static function validMoney(mixed $value, bool $allowZero = true): bool
    {
        if (!is_numeric($value)) {
            return false;
        }
        return $allowZero ? (float) $value >= 0 : (float) $value > 0;
    }
    public static function bool(mixed $value): bool
    {
        return filter_var($value, FILTER_VALIDATE_BOOLEAN);
    }
}
