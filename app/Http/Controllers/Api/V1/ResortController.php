<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Core\Request;
use App\Core\Response;
use App\Core\Session;
use App\Core\Logger;
use App\Core\NotFoundException;
use App\Http\Requests\ValidationException;
use App\Policies\ResortPolicy;
use App\Services\ResortService;
use App\Services\UploadService;
use App\Repositories\Contracts\ResortRepositoryInterface;
use App\Support\Csv;
use Throwable;
use PDOException;

final class ResortController
{
    public function __construct(private readonly ResortService $service, private readonly UploadService $uploads, private readonly ResortRepositoryInterface $repository)
    {
    }

    public function snapshot(Request $r): Response
    {
        try {
            return Response::json($this->service->snapshot((string) $r->query('start', '') ?: null, (string) $r->query('end', '') ?: null), 'โหลดข้อมูลแล้ว');
        } catch (ValidationException $e) {
            return Response::json(null, $e->getMessage(), 422, $e->errors);
        }
    }

    public function stays(Request $r): Response
    {
        $value = $r->query('status');
        if ($value !== null && $value !== '' && !in_array((string) $value, ['0', '1', '2'], true)) {
            return Response::json(null, 'สถานะไม่ถูกต้อง', 422, ['status' => 'กรุณาเลือกสถานะที่ถูกต้อง']);
        }
        $status = $value === null || $value === '' ? null : (int) $value;
        return Response::json($this->repository->searchStays((string) $r->query('search', ''), $status), 'โหลดรายการแล้ว');
    }
    public function room(Request $r): Response
    {
        return $this->mutate($r, 'manage_rooms', fn ($i, $u) => $this->service->saveRoom($i, $r->param('id'), $u, $r->ip()));
    }
    public function deleteRoom(Request $r): Response
    {
        return $this->mutate($r, 'manage_rooms', function ($i, $u) use ($r) {
            $this->service->deleteRoom((string) $r->param('id'), $u, $r->ip());
            return null;
        });
    }
    public function guest(Request $r): Response
    {
        return $this->mutate($r, 'edit_guest', fn ($i, $u) => $this->service->saveGuest($i, $r->param('id'), $u, $r->ip()));
    }
    public function stay(Request $r): Response
    {
        return $this->mutate($r, 'booking', fn ($i, $u) => $this->service->saveStay($i, $r->param('id'), $u, $r->ip()));
    }
    public function checkIn(Request $r): Response
    {
        return $this->mutate($r, 'booking', fn ($i, $u) => $this->service->checkIn((string) $r->param('id'), $u, $r->ip()));
    }
    public function checkout(Request $r): Response
    {
        return $this->mutate($r, 'checkout', fn ($i, $u) => $this->service->checkout((string) $r->param('id'), $i, $u, $r->ip()));
    }
    public function feedback(Request $r): Response
    {
        return $this->mutate($r, 'booking', fn ($i, $u) => $this->service->feedback((string) $r->param('id'), $i, $u, $r->ip()));
    }
    public function deleteStay(Request $r): Response
    {
        return $this->mutate($r, 'booking', function ($i, $u) use ($r) {
            $this->service->deleteStay((string) $r->param('id'), $u, $r->ip());
            return null;
        });
    }
    public function upload(Request $r): Response
    {
        return $this->mutate($r, 'upload', fn ($i, $u) => $this->uploads->store((string) $r->param('id'), $_FILES['file'] ?? [], $u), false);
    }
    public function export(Request $r): Response
    {
        try {
            $snapshot = $this->service->snapshot((string) $r->query('start', '') ?: null, (string) $r->query('end', '') ?: null);
        } catch (ValidationException $e) {
            return Response::json(null, $e->getMessage(), 422, $e->errors);
        }
        $lines = [["Booking ID","ชื่อลูกค้า","โทรศัพท์","ห้อง","เช็กอิน","เช็กเอาต์","สถานะ","ยอดสุทธิ (บาท)"]];
        foreach ($snapshot['stays'] as $s) {
            $lines[] = array_map([Csv::class, 'safe'], [$s['id'],$s['guest_name'],$s['phone'],$s['room_name'],$s['check_in_date'],$s['check_out_date'],$s['status'],number_format(((int) $s['total_amount_satang']) / 100, 2, '.', '')]);
        }
        $stream = fopen('php://temp', 'r+');
        foreach ($lines as $line) {
            fputcsv($stream, $line);
        } rewind($stream);
        $csv = "\xEF\xBB\xBF" . stream_get_contents($stream);
        fclose($stream);
        return Response::raw($csv, 'text/csv; charset=utf-8', ['Content-Disposition' => 'attachment; filename="stay-book-report-' . date('Y-m-d') . '.csv"']);
    }

    private function mutate(Request $request, string $ability, callable $action, bool $readInput = true): Response
    {
        $user = Session::user() ?? [];
        if (!ResortPolicy::allows($user, $ability)) {
            return Response::json(null, 'ไม่มีสิทธิ์ดำเนินการ', 403);
        }
        try {
            $result = $action($readInput ? $request->input() : [], $user);
            return Response::json($result, 'บันทึกเรียบร้อย');
        } catch (ValidationException $e) {
            return Response::json(null, $e->getMessage(), 422, $e->errors);
        } catch (NotFoundException $e) {
            return Response::json(null, $e->getMessage(), 404);
        } catch (PDOException $e) {
            Logger::error($e);
            if ((string) $e->getCode() === '23000' || str_contains(strtolower($e->getMessage()), 'unique')) {
                return Response::json(null, 'ข้อมูลนี้มีอยู่ในระบบแล้ว', 409);
            }
            return Response::json(null, 'ระบบไม่สามารถบันทึกข้อมูลได้', 500);
        } catch (Throwable $e) {
            Logger::error($e);
            return Response::json(null, 'ระบบไม่สามารถบันทึกข้อมูลได้', 500);
        }
    }
}
