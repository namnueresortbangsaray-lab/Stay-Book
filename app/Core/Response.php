<?php

declare(strict_types=1);

namespace App\Core;

final class Response
{
    /** @param array<string, string> $headers */
    public function __construct(
        private readonly string $body = '',
        private readonly int $status = 200,
        private readonly array $headers = [],
    ) {
    }

    public static function json(mixed $data = null, string $message = '', int $status = 200, array $errors = []): self
    {
        return new self(
            (string) json_encode(['success' => $status < 400, 'data' => $data, 'message' => $message, 'errors' => (object) $errors], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES),
            $status,
            ['Content-Type' => 'application/json; charset=utf-8'],
        );
    }

    public static function redirect(string $url, int $status = 302): self
    {
        return new self('', $status, ['Location' => $url]);
    }

    /** @param array<string, string> $headers */
    public static function raw(string $body, string $contentType, array $headers = []): self
    {
        return new self($body, 200, ['Content-Type' => $contentType] + $headers);
    }

    public function send(): never
    {
        http_response_code($this->status);
        foreach ($this->headers as $key => $value) {
            header("{$key}: {$value}");
        }
        echo $this->body;
        exit;
    }
}
