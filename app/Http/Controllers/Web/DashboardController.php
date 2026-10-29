<?php

declare(strict_types=1);

namespace App\Http\Controllers\Web;

use App\Core\Request;
use App\Core\Response;
use App\Core\Session;
use App\Core\View;

final class DashboardController
{
    public function index(Request $request): Response
    {
        return View::render('pages/dashboard/index', ['user' => Session::user()]);
    }
}
