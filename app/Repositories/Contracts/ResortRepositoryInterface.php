<?php

declare(strict_types=1);

namespace App\Repositories\Contracts;

interface ResortRepositoryInterface
{
    public function findUserByEmail(string $email): ?array;
    public function createUser(array $data): void;
    public function rooms(): array;
    public function saveRoom(array $data, ?string $id = null): array;
    public function deleteRoom(string $id): void;
    public function guests(): array;
    public function guest(string $id): ?array;
    public function findGuestByPhone(string $phone): ?array;
    public function saveGuest(array $data, ?string $id = null): array;
    public function stays(): array;
    public function searchStays(string $search = '', ?int $status = null): array;
    public function stay(string $id): ?array;
    public function hasOverlap(string $roomId, string $from, string $to, ?string $except = null): bool;
    public function saveStay(array $data, ?string $id = null): array;
    public function setStayStatus(string $id, int $status, string $userId, array $inspection = []): array;
    public function deleteStay(string $id, string $userId): void;
    public function saveFeedback(string $stayId, array $data): array;
    public function saveAttachment(array $data): array;
    public function attachment(string $id): ?array;
    public function attachments(?string $stayId = null): array;
    public function audit(string $action, string $type, string $id, ?array $before, ?array $after, ?string $userId, string $ip): void;
}
