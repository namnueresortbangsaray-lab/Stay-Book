<?php

declare(strict_types=1);

namespace App\Http\Controllers\Web;

use App\Core\Request;
use App\Core\Response;
use App\Core\Session;
use App\Core\View;
use App\Services\AuthService;

final class AuthController
{
    public function __construct(private readonly AuthService $auth)
    {
    }

    public function show(Request $request): Response
    {
        if (Session::user() !== null) {
            return Response::redirect('/');
        }
        return View::render('pages/auth/login', ['error' => null], 'layouts/auth');
    }
    public function login(Request $request): Response
    {
        $input = $request->input();
        if ($this->auth->isThrottled($request->ip())) {
            return View::render(
                'pages/auth/login',
                ['error' => 'ลองเข้าสู่ระบบมากเกินไป กรุณารอ 15 นาทีแล้วลองใหม่'],
                'layouts/auth',
                429,
            );
        }
        if ($this->auth->login((string) ($input['email'] ?? ''), (string) ($input['password'] ?? ''), $request->ip())) {
            return Response::redirect('/');
        }
        return View::render('pages/auth/login', ['error' => 'อีเมลหรือรหัสผ่านไม่ถูกต้อง'], 'layouts/auth');
    }
    public function logout(Request $request): Response
    {
        $this->auth->logout();
        return Response::redirect('/login');
    }
}
