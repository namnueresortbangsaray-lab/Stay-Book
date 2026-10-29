<?php

declare(strict_types=1);

namespace App\Enums;

enum Role: string
{
    case Admin = 'admin';
    case FrontDesk = 'front_desk';
    case Housekeeping = 'housekeeping';
}
