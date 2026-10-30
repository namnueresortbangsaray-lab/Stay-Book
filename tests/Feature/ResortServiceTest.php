<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Core\Config;
use App\Database\Connection;
use App\Database\Migrator;
use App\Database\Seeder;
use App\Http\Requests\ValidationException;
use App\Repositories\Database\ResortRepository;
use App\Services\ResortService;
use PHPUnit\Framework\TestCase;

final class ResortServiceTest extends TestCase
{
    private ResortRepository $repository;
    private ResortService $service;
    /** @var array<string, mixed> */
    private array $actor;

    protected function setUp(): void
    {
        $path = (string) Config::get('database.sqlite.path');
        foreach ([$path, $path . '-wal', $path . '-shm'] as $file) {
            if (is_file($file)) {
                unlink($file);
            }
        }

        $connection = new Connection('sqlite');
        (new Migrator($connection))->migrate();
        (new Seeder($connection))->seed();
        $this->repository = new ResortRepository($connection);
        $this->service = new ResortService($this->repository, $connection);
        $this->actor = $this->repository->findUserByEmail('admin@staybook.local') ?? [];
    }

    public function testCompletedStayCannotBeCreatedWithoutCheckoutWorkflow(): void
    {
        $room = $this->repository->rooms()[0];
        $this->expectException(ValidationException::class);

        $this->service->saveStay(array_replace($this->stayInput((string) $room['id']), ['status' => 2]), null, $this->actor, '127.0.0.1');
    }

    public function testOverlappingStayIsRejectedButSameDayTurnoverIsAllowed(): void
    {
        $room = $this->repository->rooms()[0];
        $roomId = (string) $room['id'];
        $this->service->saveStay($this->stayInput($roomId), null, $this->actor, '127.0.0.1');

        $turnover = array_replace($this->stayInput($roomId), [
            'guest_name' => 'ลูกค้า ถัดไป',
            'phone' => '0899999999',
            'check_in_date' => '2030-01-12',
            'check_out_date' => '2030-01-13',
        ]);
        $created = $this->service->saveStay($turnover, null, $this->actor, '127.0.0.1');
        self::assertSame('2030-01-12', $created['check_in_date']);

        $this->expectException(ValidationException::class);
        $this->service->saveStay(array_replace($this->stayInput($roomId), [
            'guest_name' => 'ลูกค้า ชนกัน',
            'phone' => '0877777777',
            'check_in_date' => '2030-01-11',
            'check_out_date' => '2030-01-13',
        ]), null, $this->actor, '127.0.0.1');
    }

    public function testBookingCanCompleteCreateCheckInAndCheckoutLifecycle(): void
    {
        $room = $this->repository->rooms()[0];
        $created = $this->service->saveStay(
            array_replace($this->stayInput((string) $room['id']), ['id_verified' => true]),
            null,
            $this->actor,
            '127.0.0.1'
        );

        self::assertSame(0, (int) $created['status']);
        $checkedIn = $this->service->checkIn((string) $created['id'], $this->actor, '127.0.0.1');
        self::assertSame(1, (int) $checkedIn['status']);

        $checkedOut = $this->service->checkout((string) $created['id'], [
            'key_returned' => true,
            'room_clean' => true,
            'equipment_complete' => true,
            'no_damage' => true,
            'minibar_checked' => true,
            'inspection_note' => '',
        ], $this->actor, '127.0.0.1');

        self::assertSame(2, (int) $checkedOut['status']);
    }

    public function testPendingBookingCanBeCancelled(): void
    {
        $room = $this->repository->rooms()[0];
        $created = $this->service->saveStay($this->stayInput((string) $room['id']), null, $this->actor, '127.0.0.1');

        self::assertNotNull($this->repository->stay((string) $created['id']));
        $this->service->deleteStay((string) $created['id'], $this->actor, '127.0.0.1');
        self::assertNull($this->repository->stay((string) $created['id']));
    }

    /** @return array<string, mixed> */
    private function stayInput(string $roomId): array
    {
        return [
            'guest_name' => 'ลูกค้า ทดสอบ',
            'phone' => '0812345678',
            'room_id' => $roomId,
            'check_in_date' => '2030-01-10',
            'check_out_date' => '2030-01-12',
            'guests' => 2,
            'extra_bed' => false,
            'status' => 0,
            'deposit_amount' => 0,
            'deposit_paid' => false,
            'id_verified' => false,
            'pet_count' => 0,
            'discount_amount' => 0,
            'note' => 'ทดสอบระบบ',
        ];
    }
}
