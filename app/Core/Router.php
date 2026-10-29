<?php

declare(strict_types=1);

namespace App\Core;

final class Router
{
    /** @var list<array{string,string,callable,bool}> */
    private array $routes = [];

    public function add(string $method, string $path, callable $handler, bool $auth = true): void
    {
        $this->routes[] = [strtoupper($method), rtrim($path, '/') ?: '/', $handler, $auth];
    }

    /** @return array{callable,Request,bool}|null */
    public function match(Request $request): ?array
    {
        $requestMethod = $request->method === 'HEAD' ? 'GET' : $request->method;
        foreach ($this->routes as [$method, $path, $handler, $auth]) {
            if ($method !== $requestMethod) {
                continue;
            }
            $names = [];
            $regex = preg_replace_callback('/\{([a-zA-Z_][a-zA-Z0-9_]*)\}/', static function (array $m) use (&$names): string {
                $names[] = $m[1];
                return '([^/]+)';
            }, $path);
            if ($regex !== null && preg_match('#^' . $regex . '$#', $request->path, $matches) === 1) {
                array_shift($matches);
                return [$handler, $request->withParams(array_combine($names, $matches) ?: []), $auth];
            }
        }
        return null;
    }
}
