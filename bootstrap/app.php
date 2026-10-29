<?php

declare(strict_types=1);

use App\Core\Application;
use App\Core\Config;
use App\Core\Container;
use App\Core\Router;
use App\Database\Connection;
use App\Http\Controllers\Api\V1\ResortController;
use App\Http\Controllers\Web\AuthController;
use App\Http\Controllers\Web\DashboardController;
use App\Http\Controllers\Web\UploadController;
use App\Repositories\Contracts\ResortRepositoryInterface;
use App\Repositories\Database\ResortRepository;
use App\Services\AuthService;
use App\Services\ResortService;
use App\Services\UploadService;

require __DIR__ . '/autoload.php';
Config::load(dirname(__DIR__) . '/config');
date_default_timezone_set((string) Config::get('app.timezone', 'Asia/Bangkok'));

$container = new Container();
$container->set(Connection::class, static fn () => new Connection());
$container->set(ResortRepositoryInterface::class, static fn (Container $c) => new ResortRepository($c->get(Connection::class)));
$container->set(AuthService::class, static fn (Container $c) => new AuthService($c->get(ResortRepositoryInterface::class)));
$container->set(ResortService::class, static fn (Container $c) => new ResortService($c->get(ResortRepositoryInterface::class), $c->get(Connection::class)));
$container->set(UploadService::class, static fn (Container $c) => new UploadService($c->get(ResortRepositoryInterface::class)));
$container->set(AuthController::class, static fn (Container $c) => new AuthController($c->get(AuthService::class)));
$container->set(DashboardController::class, static fn () => new DashboardController());
$container->set(UploadController::class, static fn (Container $c) => new UploadController($c->get(ResortRepositoryInterface::class)));
$container->set(ResortController::class, static fn (Container $c) => new ResortController($c->get(ResortService::class), $c->get(UploadService::class), $c->get(ResortRepositoryInterface::class)));

$router = new Router();
(require dirname(__DIR__) . '/routes/web.php')($router, $container);
(require dirname(__DIR__) . '/routes/api.php')($router, $container);
return new Application($router);
