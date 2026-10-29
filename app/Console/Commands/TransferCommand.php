<?php

declare(strict_types=1);

namespace App\Console\Commands;

use App\Database\Transfer;

final class TransferCommand implements CommandInterface
{
    public function run(array $a): int
    {
        $from = 'sqlite';
        $to = 'pgsql';
        $truncate = in_array('--truncate', $a, true);
        $dry = in_array('--dry-run', $a, true);
        foreach ($a as $v) {
            if (str_starts_with($v, '--from=')) {
                $from = substr($v, 7);
            }if (str_starts_with($v, '--to=')) {
                $to = substr($v, 5);
            }
        } $counts = (new Transfer())->run($from, $to, $truncate, $dry);
        foreach ($counts as $t => $c) {
            echo sprintf("%-24s %d -> %d\n", $t, $c['source'], $c['target']);
        } return 0;
    }
}
