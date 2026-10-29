<?php

declare(strict_types=1);

namespace App\Services;

use App\Database\Connection;
use App\Core\NotFoundException;
use App\Http\Requests\RoomRequest;
use App\Http\Requests\StayRequest;
use App\Http\Requests\ValidationException;
use App\Models\PriceCalculator;
use App\Repositories\Contracts\ResortRepositoryInterface;
use App\Support\Str;
use DateTimeImmutable;

final class ResortService
{
    public function __construct(private readonly ResortRepositoryInterface $repository, private readonly Connection $connection)
    {
    }

    public function snapshot(?string $start = null, ?string $end = null): array
    {
        $start ??= date('Y-m-01');
        $end ??= date('Y-m-t');
        $this->validateRange($start, $end);
        $rooms = $this->repository->rooms();
        $stays = $this->repository->stays();
        $guests = $this->repository->guests();
        return ['rooms' => $rooms, 'stays' => $stays, 'guests' => $guests, 'attachments' => $this->repository->attachments(), 'analytics' => $this->analytics($rooms, $stays, $start, $end), 'today' => date('Y-m-d')];
    }

    public function saveRoom(array $input, ?string $id, array $actor, string $ip): array
    {
        $data = RoomRequest::validate($input);
        $data['is_pet_friendly'] = $this->connection->dialect()->boolean($data['is_pet_friendly']);
        $before = $id ? $this->findById($this->repository->rooms(), $id) : null;
        if ($id !== null && $before === null) {
            throw new NotFoundException('ไม่พบห้องพัก');
        }
        $after = $this->repository->saveRoom($data, $id);
        $this->repository->audit($id ? 'update' : 'create', 'room', (string) $after['id'], $before, $after, (string) $actor['id'], $ip);
        return $after;
    }

    public function deleteRoom(string $id, array $actor, string $ip): void
    {
        $before = $this->findById($this->repository->rooms(), $id);
        if ($before === null) {
            throw new NotFoundException('ไม่พบห้องพัก');
        }
        $this->repository->deleteRoom($id);
        $this->repository->audit('delete', 'room', $id, $before, null, (string) $actor['id'], $ip);
    }

    public function saveGuest(array $input, ?string $id, array $actor, string $ip): array
    {
        $name = trim((string) ($input['name'] ?? ''));
        $phone = trim((string) ($input['phone'] ?? ''));
        $normalized = Str::phone($phone);
        $errors = [];
        if (mb_strlen($name) < 2) {
            $errors['name'] = 'กรุณากรอกชื่ออย่างน้อย 2 ตัวอักษร';
        } if (strlen($normalized) < 9) {
            $errors['phone'] = 'เบอร์โทรต้องมีอย่างน้อย 9 หลัก';
        } if ($errors) {
            throw new ValidationException($errors);
        }
        $data = ['name' => $name, 'phone' => $phone, 'normalized_phone' => $normalized, 'customer_type' => trim((string) ($input['customer_type'] ?? 'ลูกค้าทั่วไป')), 'is_regular' => $this->connection->dialect()->boolean(RoomRequest::bool($input['is_regular'] ?? false)), 'customer_note' => Str::clean($input['customer_note'] ?? null), 'preferences' => Str::clean($input['preferences'] ?? null)];
        $before = $id ? $this->repository->guest($id) : null;
        if ($id !== null && $before === null) {
            throw new NotFoundException('ไม่พบลูกค้า');
        }
        $after = $this->repository->saveGuest($data, $id);
        $this->repository->audit($id ? 'update' : 'create', 'guest', (string) $after['id'], $before, $after, (string) $actor['id'], $ip);
        return $after;
    }

    public function saveStay(array $input, ?string $id, array $actor, string $ip): array
    {
        $data = StayRequest::validate($input);
        $before = $id ? $this->repository->stay($id) : null;
        if ($id !== null && $before === null) {
            throw new ValidationException(['id' => 'ไม่พบ Booking']);
        }
        if ($id === null && $data['status'] === 2) {
            throw new ValidationException(['status' => 'ต้องเช็กอินและตรวจห้องก่อนเช็กเอาต์']);
        }
        if ($before !== null) {
            if ((int) $before['status'] === 2) {
                throw new ValidationException(['status' => 'Booking ที่เช็กเอาต์แล้วไม่สามารถแก้ไขได้']);
            }
            if ((int) $before['status'] === 1 && $data['room_id'] !== $before['room_id']) {
                throw new ValidationException(['room_id' => 'ไม่สามารถย้ายห้องระหว่างเข้าพักได้ กรุณาเช็กเอาต์ก่อน']);
            }
            $data['status'] = (int) $before['status'];
        }
        $room = $this->findById($this->repository->rooms(), $data['room_id']);
        if ($room === null) {
            throw new ValidationException(['room_id' => 'ไม่พบห้องพัก']);
        }
        if ($data['guests'] > (int) $room['max_guests']) {
            throw new ValidationException(['guests' => 'จำนวนผู้เข้าพักเกินความจุห้อง']);
        }
        if ($data['pet_count'] > 0 && !$room['is_pet_friendly']) {
            throw new ValidationException(['room_id' => 'ห้องนี้ไม่รองรับสัตว์เลี้ยง']);
        }
        if ($this->repository->hasOverlap($data['room_id'], $data['check_in_date'], $data['check_out_date'], $id)) {
            throw new ValidationException(['room_id' => 'ห้องนี้มี Booking ทับซ้อนในช่วงวันที่เลือก']);
        }
        $guest = $this->repository->findGuestByPhone($data['phone']);
        if ($guest === null) {
            $guest = $this->repository->saveGuest(['name' => $data['guest_name'], 'phone' => $data['phone'], 'normalized_phone' => Str::phone($data['phone']), 'customer_type' => 'ลูกค้าทั่วไป', 'is_regular' => $this->connection->dialect()->boolean(false), 'customer_note' => null, 'preferences' => null]);
        }
        $price = PriceCalculator::calculate($room, $data['guests'], $data['check_in_date'], $data['check_out_date'], $data['extra_bed'], $data['pet_count'], $data['discount_amount_satang'], $data['deposit_amount_satang'], $data['deposit_paid']);
        $data += ['guest_id' => $guest['id'], 'total_amount_satang' => $price['total_amount_satang'], 'pet_fee_satang' => $price['pet_total_satang']];
        foreach (['extra_bed','deposit_paid','id_verified'] as $key) {
            $data[$key] = $this->connection->dialect()->boolean($data[$key]);
        }
        $after = $this->repository->saveStay($data, $id);
        $after['price_breakdown'] = $price;
        $this->repository->audit($id ? 'update' : 'create', 'stay', (string) $after['id'], $before, $after, (string) $actor['id'], $ip);
        return $after;
    }

    public function checkIn(string $id, array $actor, string $ip): array
    {
        $before = $this->repository->stay($id) ?? throw new NotFoundException('ไม่พบ Booking');
        if ((int) $before['status'] !== 0) {
            throw new ValidationException(['status' => 'Booking นี้ไม่อยู่ในสถานะรอเช็กอิน']);
        }
        if (!$before['id_verified']) {
            throw new ValidationException(['id_verified' => 'ต้องตรวจสอบบัตรประชาชนก่อนเช็กอิน']);
        }
        if ($this->repository->hasOverlap((string) $before['room_id'], (string) $before['check_in_date'], (string) $before['check_out_date'], $id)) {
            throw new ValidationException(['room_id' => 'ห้องมีรายการเข้าพักอื่นทับซ้อน']);
        }
        $after = $this->repository->setStayStatus($id, 1, (string) $actor['id']);
        $this->repository->audit('check_in', 'stay', $id, $before, $after, (string) $actor['id'], $ip);
        return $after;
    }

    public function checkout(string $id, array $input, array $actor, string $ip): array
    {
        $before = $this->repository->stay($id) ?? throw new NotFoundException('ไม่พบ Booking');
        if ((int) $before['status'] !== 1) {
            throw new ValidationException(['status' => 'Booking นี้ยังไม่ได้เช็กอิน']);
        }
        $keys = ['key_returned','room_clean','equipment_complete','no_damage','minibar_checked'];
        $inspection = [];
        foreach ($keys as $key) {
            $inspection[$key] = $this->connection->dialect()->boolean(RoomRequest::bool($input[$key] ?? false));
        }
        $inspection['inspection_note'] = Str::clean($input['inspection_note'] ?? null);
        if (!RoomRequest::bool($input['no_damage'] ?? false) && $inspection['inspection_note'] === null) {
            throw new ValidationException(['inspection_note' => 'กรุณาระบุรายละเอียดความเสียหาย']);
        }
        $after = $this->repository->setStayStatus($id, 2, (string) $actor['id'], $inspection);
        $this->repository->audit('check_out', 'stay', $id, $before, $after, (string) $actor['id'], $ip);
        return $after;
    }

    public function feedback(string $id, array $input, array $actor, string $ip): array
    {
        $stay = $this->repository->stay($id) ?? throw new NotFoundException('ไม่พบ Booking');
        if ((int) $stay['status'] !== 2) {
            throw new ValidationException(['status' => 'บันทึก Feedback ได้หลังเช็กเอาต์เท่านั้น']);
        }
        $data = [];
        foreach (['cleanliness_rating','service_rating','facility_rating','overall_rating'] as $key) {
            $data[$key] = (int) ($input[$key] ?? 0);
            if ($data[$key] < 1 || $data[$key] > 5) {
                throw new ValidationException([$key => 'คะแนนต้องอยู่ระหว่าง 1–5']);
            }
        }
        $data['would_return'] = $this->connection->dialect()->boolean(RoomRequest::bool($input['would_return'] ?? true));
        $data['comment'] = Str::clean($input['comment'] ?? null);
        $after = $this->repository->saveFeedback($id, $data);
        $this->repository->audit('feedback', 'stay', $id, null, $after, (string) $actor['id'], $ip);
        return $after;
    }

    public function deleteStay(string $id, array $actor, string $ip): void
    {
        $before = $this->repository->stay($id) ?? throw new NotFoundException('ไม่พบ Booking');
        $this->repository->deleteStay($id, (string) $actor['id']);
        $this->repository->audit('delete', 'stay', $id, $before, null, (string) $actor['id'], $ip);
    }

    private function analytics(array $rooms, array $stays, string $start, string $end): array
    {
        $days = max(1, (int) ((strtotime($end) - strtotime($start)) / 86400) + 1);
        $started = array_values(array_filter($stays, static fn ($s) => $s['check_in_date'] >= $start && $s['check_in_date'] <= $end));
        $charts = [];
        $occupiedNights = 0;
        for ($t = strtotime($start); $t <= strtotime($end); $t += 86400) {
            $d = date('Y-m-d', $t);
            $present = count(array_filter($stays, static fn ($s) => $s['check_in_date'] <= $d && $s['check_out_date'] > $d));
            $revenue = array_sum(array_map(static fn ($s) => $s['check_in_date'] === $d && (int) $s['status'] !== 0 ? (int) $s['total_amount_satang'] : 0, $stays));
            $charts[] = ['date' => $d, 'occupied' => $present, 'revenue_satang' => $revenue];
            $occupiedNights += $present;
        }
        $billable = array_filter($started, static fn ($s) => (int) $s['status'] !== 0);
        $feedback = array_filter($started, static fn ($s) => $s['feedback_rating'] !== null);
        $status = [0 => 0,1 => 0,2 => 0];
        $deposits = ['none' => 0,'paid' => 0,'unpaid' => 0];
        foreach ($started as $s) {
            $status[(int) $s['status']]++;
            if ((int) $s['deposit_amount_satang'] === 0) {
                $deposits['none']++;
            } elseif ($s['deposit_paid']) {
                $deposits['paid']++;
            } else {
                $deposits['unpaid']++;
            }
        }
        return ['start' => $start, 'end' => $end, 'day_count' => $days, 'total_rooms' => count($rooms), 'booking_count' => count($started), 'check_in_count' => count(array_filter($started, static fn ($s) => (int) $s['status'] >= 1)), 'check_out_count' => $status[2], 'guest_count' => array_sum(array_column($started, 'guests')), 'occupied_room_nights' => $occupiedNights, 'occupancy_rate' => count($rooms) ? $occupiedNights / (count($rooms) * $days) : 0, 'gross_revenue_satang' => array_sum(array_map(static fn ($s) => (int) $s['total_amount_satang'] + (int) $s['discount_amount_satang'], $billable)), 'discount_satang' => array_sum(array_column($billable, 'discount_amount_satang')), 'net_revenue_satang' => array_sum(array_column($billable, 'total_amount_satang')), 'deposit_received_satang' => array_sum(array_map(static fn ($s) => $s['deposit_paid'] ? (int) $s['deposit_amount_satang'] : 0, $started)), 'deposit_pending_satang' => array_sum(array_map(static fn ($s) => !$s['deposit_paid'] ? (int) $s['deposit_amount_satang'] : 0, $started)), 'pet_bookings' => count(array_filter($started, static fn ($s) => (int) $s['pet_count'] > 0)), 'average_feedback' => count($feedback) ? array_sum(array_column($feedback, 'feedback_rating')) / count($feedback) : 0, 'statuses' => ['booked' => $status[0],'checked_in' => $status[1],'checked_out' => $status[2]], 'deposits' => $deposits, 'daily' => $charts];
    }

    private function validateRange(string $start, string $end): void
    {
        $from = DateTimeImmutable::createFromFormat('!Y-m-d', $start);
        $to = DateTimeImmutable::createFromFormat('!Y-m-d', $end);
        if ($from === false || $from->format('Y-m-d') !== $start) {
            throw new ValidationException(['start' => 'วันที่เริ่มต้นไม่ถูกต้อง']);
        }
        if ($to === false || $to->format('Y-m-d') !== $end) {
            throw new ValidationException(['end' => 'วันที่สิ้นสุดไม่ถูกต้อง']);
        }
        if ($to < $from) {
            throw new ValidationException(['end' => 'วันที่สิ้นสุดต้องไม่น้อยกว่าวันที่เริ่มต้น']);
        }
        if ($from->diff($to)->days > 366) {
            throw new ValidationException(['end' => 'ช่วงรายงานต้องไม่เกิน 366 วัน']);
        }
    }

    private function findById(array $items, string $id): ?array
    {
        foreach ($items as $item) {
            if (($item['id'] ?? null) === $id) {
                return $item;
            }
        } return null;
    }
}
