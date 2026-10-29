<?php

declare(strict_types=1);

namespace App\Services;

use App\Core\Config;
use App\Core\NotFoundException;
use App\Repositories\Contracts\ResortRepositoryInterface;
use App\Support\Date;
use App\Support\Uuid;
use RuntimeException;
use Throwable;

final class UploadService
{
    public function __construct(private readonly ResortRepositoryInterface $repository)
    {
    }

    public function store(string $stayId, array $file, array $actor): array
    {
        if ($this->repository->stay($stayId) === null) {
            throw new NotFoundException('ไม่พบ Booking');
        }
        if (($file['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_OK) {
            throw new RuntimeException('อัปโหลดไฟล์ไม่สำเร็จ');
        }
        $size = (int) ($file['size'] ?? 0);
        if ($size < 1 || $size > (int) Config::get('uploads.max_bytes')) {
            throw new RuntimeException('ไฟล์มีขนาดไม่ถูกต้องหรือใหญ่เกินกำหนด');
        }
        $tmp = (string) $file['tmp_name'];
        $mime = (new \finfo(FILEINFO_MIME_TYPE))->file($tmp);
        $allowed = Config::get('uploads.mimes');
        if (!is_string($mime) || !is_array($allowed) || !isset($allowed[$mime])) {
            throw new RuntimeException('ประเภทไฟล์ไม่ได้รับอนุญาต');
        }
        $stored = bin2hex(random_bytes(24)) . '.' . $allowed[$mime];
        $path = (string) Config::get('uploads.path');
        if (!is_dir($path)) {
            mkdir($path, 0770, true);
        }
        $destination = $path . '/' . $stored;
        if (!move_uploaded_file($tmp, $destination)) {
            throw new RuntimeException('ไม่สามารถจัดเก็บไฟล์ได้');
        }
        try {
            return $this->repository->saveAttachment(['id' => Uuid::make(), 'stay_id' => $stayId, 'uploaded_by' => $actor['id'], 'original_name' => basename((string) $file['name']), 'stored_name' => $stored, 'mime_type' => $mime, 'size_bytes' => $size, 'created_at' => Date::now()]);
        } catch (Throwable $exception) {
            if (is_file($destination)) {
                unlink($destination);
            }
            throw $exception;
        }
    }
}
