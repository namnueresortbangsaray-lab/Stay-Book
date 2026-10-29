<?php

declare(strict_types=1);

use App\Core\Container;
use App\Core\Router;
use App\Http\Controllers\Api\V1\ResortController;

return static function (Router $r, Container $c): void {
    $x = $c->get(ResortController::class);
    $r->add('GET', '/api/v1/snapshot', [$x, 'snapshot']);
    $r->add('GET', '/api/v1/stays', [$x, 'stays']);
    $r->add('POST', '/api/v1/rooms', [$x, 'room']);
    $r->add('PUT', '/api/v1/rooms/{id}', [$x, 'room']);
    $r->add('DELETE', '/api/v1/rooms/{id}', [$x, 'deleteRoom']);
    $r->add('PUT', '/api/v1/guests/{id}', [$x, 'guest']);
    $r->add('POST', '/api/v1/stays', [$x, 'stay']);
    $r->add('PUT', '/api/v1/stays/{id}', [$x, 'stay']);
    $r->add('DELETE', '/api/v1/stays/{id}', [$x, 'deleteStay']);
    $r->add('POST', '/api/v1/stays/{id}/check-in', [$x, 'checkIn']);
    $r->add('POST', '/api/v1/stays/{id}/checkout', [$x, 'checkout']);
    $r->add('POST', '/api/v1/stays/{id}/feedback', [$x, 'feedback']);
    $r->add('POST', '/api/v1/stays/{id}/attachments', [$x, 'upload']);
    $r->add('GET', '/api/v1/reports/bookings.csv', [$x, 'export']);
};
