<?php

declare(strict_types=1);

namespace App\Core;

use Throwable;

final class Application
{
    public function __construct(private readonly Router $router)
    {
    }

    public function run(): never
    {
        Session::start();
        $request = Request::capture();
        try {
            $matched = $this->router->match($request);
            if ($matched === null) {
                $this->error($request, 404, 'ไม่พบหน้าที่ต้องการ');
            }
            [$handler, $request, $auth] = $matched;
            if ($auth && Session::user() === null) {
                ($request->isApi() ? Response::json(null, 'กรุณาเข้าสู่ระบบ', 401) : Response::redirect('/login'))->send();
            }
            if (!in_array($request->method, ['GET', 'HEAD'], true) && !Session::validateCsrf($request)) {
                $this->error($request, 419, 'เซสชันหมดอายุ กรุณาลองใหม่');
            }
            $response = $handler($request);
            if (!$response instanceof Response) {
                throw new \RuntimeException('Route handlers must return a Response.');
            }
            $response->send();
        } catch (Throwable $error) {
            Logger::error($error);
            $this->error($request, 500, 'ระบบขัดข้อง กรุณาลองใหม่');
        }
    }

    private function error(Request $request, int $status, string $message): never
    {
        if ($request->isApi()) {
            Response::json(null, $message, $status)->send();
        }
        View::render('errors/error', ['status' => $status, 'message' => $message], 'layouts/base', $status)->send();
    }
}
