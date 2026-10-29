<?php

declare(strict_types=1);

namespace App\Services;

use App\Core\Config;
use App\Repositories\Contracts\ResortRepositoryInterface;

final class AuthService
{
    public function __construct(private readonly ResortRepositoryInterface $repository)
    {
    }

    public function login(string $email, string $password, string $ip): bool
    {
        if ($this->isThrottled($ip)) {
            return false;
        }
        $user = $this->repository->findUserByEmail($email);
        if ($user === null || !password_verify($password, (string) $user['password_hash'])) {
            $this->recordFailure($ip);
            return false;
        }
        session_regenerate_id(true);
        $_SESSION['user'] = ['id' => $user['id'], 'name' => $user['name'], 'email' => $user['email'], 'role' => $user['role']];
        $this->clearFailures($ip);
        return true;
    }

    public function isThrottled(string $ip): bool
    {
        return count($this->failures($ip)) >= (int) Config::get('security.login_attempts');
    }

    public function logout(): void
    {
        $_SESSION = [];
        if (ini_get('session.use_cookies')) {
            $p = session_get_cookie_params();
            setcookie(session_name(), '', time() - 42000, $p['path'], $p['domain'], $p['secure'], $p['httponly']);
        }
        session_destroy();
    }

    private function file(string $ip): string
    {
        return dirname(__DIR__, 2) . '/storage/cache/login-' . hash('sha256', $ip) . '.json';
    }
    private function failures(string $ip): array
    {
        $f = $this->file($ip);
        $d = is_file($f) ? json_decode((string) file_get_contents($f), true) : [];
        $window = (int) Config::get('security.login_window_seconds');
        return is_array($d) ? array_values(array_filter($d, static fn ($t) => is_int($t) && $t > time() - $window)) : [];
    }
    private function recordFailure(string $ip): void
    {
        $directory = dirname($this->file($ip));
        if (!is_dir($directory)) {
            mkdir($directory, 0770, true);
        }
        $v = $this->failures($ip);
        $v[] = time();
        file_put_contents($this->file($ip), json_encode($v), LOCK_EX);
    }
    private function clearFailures(string $ip): void
    {
        $f = $this->file($ip);
        if (is_file($f)) {
            unlink($f);
        }
    }
}
