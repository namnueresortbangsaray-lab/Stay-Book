<?php

declare(strict_types=1);

namespace App\Console\Commands;

use App\Database\Connection;
use App\Repositories\Database\ResortRepository;
use App\Support\Date;
use App\Support\Uuid;

final class UserCreateCommand implements CommandInterface
{
    public function run(array $a): int
    {
        $o = $this->options($a);
        foreach (['email','password','name'] as $k) {
            if (empty($o[$k])) {
                fwrite(STDERR, "Missing --{$k}\n");
                return 1;
            }
        } $role = $o['role'] ?? 'front_desk';
        if (!in_array($role, ['admin','front_desk','housekeeping'], true)) {
            fwrite(STDERR, "Invalid role.\n");
            return 1;
        } $now = Date::now();
        (new ResortRepository(new Connection()))->createUser(['id' => Uuid::make(),'name' => $o['name'],'email' => strtolower($o['email']),'password_hash' => password_hash($o['password'], PASSWORD_DEFAULT),'role' => $role,'created_at' => $now,'updated_at' => $now]);
        echo "User created.\n";
        return 0;
    }
    private function options(array $args): array
    {
        $o = [];
        foreach ($args as $arg) {
            if (str_starts_with($arg, '--') && str_contains($arg, '=')) {
                [$k,$v] = explode('=', substr($arg, 2), 2);
                $o[$k] = $v;
            }
        } return $o;
    }
}
