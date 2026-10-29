<?php

declare(strict_types=1);

namespace App\Database;

use App\Core\Config;
use App\Repositories\Database\ResortRepository;
use App\Support\Date;
use App\Support\Uuid;

final class Seeder
{
    public function __construct(private readonly Connection $connection)
    {
    }

    public function seed(): void
    {
        $repo = new ResortRepository($this->connection);
        $email = strtolower((string) Config::env('DEMO_ADMIN_EMAIL', 'admin@staybook.local'));
        if ($repo->findUserByEmail($email) === null) {
            $now = Date::now();
            $repo->createUser(['id' => Uuid::make(), 'name' => 'ผู้ดูแลระบบ', 'email' => $email, 'password_hash' => password_hash((string) Config::env('DEMO_ADMIN_PASSWORD', 'ChangeMe123!'), PASSWORD_DEFAULT), 'role' => 'admin', 'created_at' => $now, 'updated_at' => $now]);
        }
        if ($repo->rooms() !== []) {
            return;
        }
        $rooms = require dirname(__DIR__, 2) . '/database/seeders/rooms.php';
        foreach ($rooms as $room) {
            $room['is_pet_friendly'] = $this->connection->dialect()->boolean($room['is_pet_friendly']);
            $repo->saveRoom($room);
        }
    }
}
