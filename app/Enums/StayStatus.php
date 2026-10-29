<?php

declare(strict_types=1);

namespace App\Enums;

enum StayStatus: int
{
    case Booked = 0;
    case CheckedIn = 1;
    case CheckedOut = 2;
}
