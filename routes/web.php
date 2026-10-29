<?php

declare(strict_types=1);

use App\Core\Container;
use App\Core\Router;
use App\Http\Controllers\Web\AuthController;
use App\Http\Controllers\Web\DashboardController;
use App\Http\Controllers\Web\UploadController;

return static function (Router $r, Container $c): void {
    $r->add('GET', '/login', [$c->get(AuthController::class), 'show'], false);
    $r->add('POST', '/login', [$c->get(AuthController::class), 'login'], false);
    $r->add('POST', '/logout', [$c->get(AuthController::class), 'logout']);
    $r->add('GET', '/', [$c->get(DashboardController::class), 'index']);
    $r->add('GET', '/files/{id}', [$c->get(UploadController::class), 'download']);
};
