<?php

declare(strict_types=1);

namespace App\Http\Requests;

use App\Support\Str;
use DateTimeImmutable;

final class StayRequest
{
    public static function validate(array $input): array
    {
        $errors = [];
        $name = trim((string) ($input['guest_name'] ?? ''));
        $phone = trim((string) ($input['phone'] ?? ''));
        $from = (string) ($input['check_in_date'] ?? '');
        $to = (string) ($input['check_out_date'] ?? '');
        if (mb_strlen($name) < 2) {
            $errors['guest_name'] = 'ชื่อลูกค้าต้องมีอย่างน้อย 2 ตัวอักษร';
        }
        if (strlen(Str::phone($phone)) < 9) {
            $errors['phone'] = 'เบอร์โทรต้องมีอย่างน้อย 9 หลัก';
        }
        if (!self::date($from)) {
            $errors['check_in_date'] = 'วันที่เช็กอินไม่ถูกต้อง';
        }
        if (!self::date($to) || ($from !== '' && $to <= $from)) {
            $errors['check_out_date'] = 'วันที่เช็กเอาต์ต้องอยู่หลังวันเช็กอิน';
        }
        if (trim((string) ($input['room_id'] ?? '')) === '') {
            $errors['room_id'] = 'กรุณาเลือกห้อง';
        }
        if ((int) ($input['guests'] ?? 0) < 1) {
            $errors['guests'] = 'จำนวนผู้เข้าพักต้องอย่างน้อย 1';
        }
        $petCount = max(0, (int) ($input['pet_count'] ?? 0));
        $petType = trim((string) ($input['pet_type'] ?? ''));
        if ($petCount > 0 && $petType === '') {
            $errors['pet_type'] = 'กรุณาระบุประเภทสัตว์เลี้ยง';
        }
        foreach (['deposit_amount' => 'เงินมัดจำ', 'discount_amount' => 'ส่วนลด'] as $key => $label) {
            if (!RoomRequest::validMoney($input[$key] ?? 0)) {
                $errors[$key] = "{$label}ต้องเป็นตัวเลขที่ไม่ติดลบ";
            }
        }
        $status = (int) ($input['status'] ?? 0);
        if (!in_array($status, [0,1,2], true)) {
            $errors['status'] = 'สถานะไม่ถูกต้อง';
        }
        if ($status === 1 && !RoomRequest::bool($input['id_verified'] ?? false)) {
            $errors['id_verified'] = 'ต้องตรวจสอบบัตรประชาชนก่อนเช็กอิน';
        }
        if ($errors) {
            throw new ValidationException($errors);
        }
        return ['guest_name' => $name, 'phone' => $phone, 'room_id' => (string) $input['room_id'], 'check_in_date' => $from, 'check_out_date' => $to, 'guests' => (int) $input['guests'], 'extra_bed' => RoomRequest::bool($input['extra_bed'] ?? false), 'status' => $status, 'note' => trim((string) ($input['note'] ?? '')) ?: null, 'deposit_amount_satang' => RoomRequest::money($input['deposit_amount'] ?? 0), 'deposit_paid' => RoomRequest::bool($input['deposit_paid'] ?? false), 'id_verified' => RoomRequest::bool($input['id_verified'] ?? false), 'pet_type' => $petCount > 0 ? $petType : null, 'pet_count' => $petCount, 'discount_amount_satang' => RoomRequest::money($input['discount_amount'] ?? 0)];
    }

    private static function date(string $value): bool
    {
        $d = DateTimeImmutable::createFromFormat('!Y-m-d', $value);
        return $d !== false && $d->format('Y-m-d') === $value;
    }
}
