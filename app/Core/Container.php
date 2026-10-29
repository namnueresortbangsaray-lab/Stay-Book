<?php

declare(strict_types=1);

namespace App\Core;

use RuntimeException;

final class Container
{
    /** @var array<string, callable|object> */
    private array $bindings = [];

    public function set(string $id, callable|object $value): void
    {
        $this->bindings[$id] = $value;
    }

    public function get(string $id): object
    {
        if (!isset($this->bindings[$id])) {
            throw new RuntimeException("Container binding not found: {$id}");
        }
        if (is_callable($this->bindings[$id])) {
            $this->bindings[$id] = ($this->bindings[$id])($this);
        }
        return $this->bindings[$id];
    }
}
