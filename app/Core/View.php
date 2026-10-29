<?php

declare(strict_types=1);

namespace App\Core;

use RuntimeException;

final class View
{
    /** @param array<string, mixed> $data */
    public static function render(string $name, array $data = [], string $layout = 'layouts/base', int $status = 200): Response
    {
        $root = dirname(__DIR__, 2) . '/resources/views/';
        $view = $root . $name . '.php';
        if (!is_file($view)) {
            throw new RuntimeException("View not found: {$name}");
        }
        extract($data, EXTR_SKIP);
        ob_start();
        require $view;
        $content = (string) ob_get_clean();
        $layoutFile = $root . $layout . '.php';
        ob_start();
        require $layoutFile;
        return new Response((string) ob_get_clean(), $status);
    }

    public static function e(mixed $value): string
    {
        return htmlspecialchars((string) $value, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
    }

    /** @return array<string, string> */
    public static function assets(): array
    {
        $path = dirname(__DIR__, 2) . '/public/build/manifest.json';
        $data = is_file($path) ? json_decode((string) file_get_contents($path), true) : [];
        return is_array($data) ? $data : [];
    }
}
