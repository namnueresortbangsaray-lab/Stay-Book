<?php

declare(strict_types=1);

namespace App\Core;

final class Session
{
    public static function start(): void
    {
        if (session_status() === PHP_SESSION_ACTIVE) {
            return;
        }
        $path = (string) Config::get('session.path');
        if (!is_dir($path)) {
            mkdir($path, 0770, true);
        }
        ini_set('session.gc_maxlifetime', (string) Config::get('session.lifetime', 7200));
        session_save_path($path);
        session_set_cookie_params([
            'lifetime' => (int) Config::get('session.lifetime', 7200),
            'path' => '/',
            'secure' => (bool) Config::get('session.secure', false),
            'httponly' => true,
            'samesite' => 'Lax',
        ]);
        session_start();
    }

    public static function csrf(): string
    {
        if (!isset($_SESSION['_csrf'])) {
            $_SESSION['_csrf'] = bin2hex(random_bytes(32));
        }
        return (string) $_SESSION['_csrf'];
    }

    public static function validateCsrf(Request $request): bool
    {
        $input = $request->input();
        $token = $_SERVER['HTTP_X_CSRF_TOKEN'] ?? $input['_token'] ?? '';
        return is_string($token) && hash_equals(self::csrf(), $token);
    }

    /** @return array<string, mixed>|null */
    public static function user(): ?array
    {
        return isset($_SESSION['user']) && is_array($_SESSION['user']) ? $_SESSION['user'] : null;
    }
}
