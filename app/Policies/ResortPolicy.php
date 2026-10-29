<?php

declare(strict_types=1);

namespace App\Policies;

final class ResortPolicy
{
    public static function allows(array $user, string $action): bool
    {
        $role = (string) ($user['role'] ?? '');
        if ($role === 'admin') {
            return true;
        }
        if ($role === 'front_desk') {
            return !in_array($action, ['manage_users'], true);
        }
        return $role === 'housekeeping' && in_array($action, ['view', 'checkout', 'upload'], true);
    }
}
