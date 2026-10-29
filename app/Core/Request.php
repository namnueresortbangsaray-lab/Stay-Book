<?php

declare(strict_types=1);

namespace App\Core;

final class Request
{
    /** @param array<string, string> $params */
    public function __construct(
        public readonly string $method,
        public readonly string $path,
        private array $params = [],
    ) {
    }

    public static function capture(): self
    {
        $path = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';
        $method = strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET');
        if ($method === 'POST' && isset($_POST['_method'])) {
            $method = strtoupper((string) $_POST['_method']);
        }
        return new self($method, rtrim($path, '/') ?: '/');
    }

    /** @param array<string, string> $params */
    public function withParams(array $params): self
    {
        return new self($this->method, $this->path, $params);
    }

    public function param(string $key): ?string
    {
        return $this->params[$key] ?? null;
    }

    /** @return array<string, mixed> */
    public function input(): array
    {
        $type = $_SERVER['CONTENT_TYPE'] ?? '';
        if (str_contains($type, 'application/json')) {
            $decoded = json_decode((string) file_get_contents('php://input'), true);
            return is_array($decoded) ? $decoded : [];
        }
        return $_POST;
    }

    public function query(string $key, mixed $default = null): mixed
    {
        return $_GET[$key] ?? $default;
    }

    public function ip(): string
    {
        return (string) ($_SERVER['REMOTE_ADDR'] ?? 'unknown');
    }

    public function isApi(): bool
    {
        return str_starts_with($this->path, '/api/');
    }
}
