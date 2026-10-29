<?php

declare(strict_types=1);

namespace Tests\Unit;

use App\Core\Request;
use App\Core\Response;
use App\Core\Router;
use PHPUnit\Framework\TestCase;

final class RouterTest extends TestCase
{
    public function testHeadRequestsUseTheGetRoute(): void
    {
        $router = new Router();
        $router->add('GET', '/login', static fn (): Response => new Response('ok'), false);

        self::assertNotNull($router->match(new Request('HEAD', '/login')));
    }
}
