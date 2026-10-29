<?php

declare(strict_types=1);

namespace App\Database;

use PDO;
use RuntimeException;

final class Transfer
{
    private const TABLES = ['users','rooms','guests','stays','checkout_inspections','feedbacks','attachments','audit_logs'];
    private const BOOLS = ['users' => ['active'],'rooms' => ['is_pet_friendly'],'guests' => ['is_regular'],'stays' => ['extra_bed','deposit_paid','id_verified'],'checkout_inspections' => ['key_returned','room_clean','equipment_complete','no_damage','minibar_checked'],'feedbacks' => ['would_return']];

    /** @return array<string, array{source:int,target:int}> */
    public function run(string $from, string $to, bool $truncate = false, bool $dryRun = false): array
    {
        if ($from === $to || !in_array($from, ['sqlite','pgsql'], true) || !in_array($to, ['sqlite','pgsql'], true)) {
            throw new RuntimeException('Drivers must be different sqlite/pgsql values.');
        }
        $source = new Connection($from);
        $target = new Connection($to);
        (new Migrator($target))->migrate();
        $src = $source->pdo();
        $dst = $target->pdo();
        $counts = [];
        if (!$dryRun) {
            $dst->beginTransaction();
        }
        try {
            if ($truncate && !$dryRun) {
                foreach (array_reverse(self::TABLES) as $table) {
                    $dst->exec('DELETE FROM ' . $table);
                }
            }
            foreach (self::TABLES as $table) {
                $rows = $src->query('SELECT * FROM ' . $table)->fetchAll();
                foreach ($rows as $row) {
                    foreach (self::BOOLS[$table] ?? [] as $key) {
                        $row[$key] = $target->dialect()->boolean(filter_var($row[$key], FILTER_VALIDATE_BOOLEAN));
                    }
                    if ($dryRun) {
                        continue;
                    }
                    $columns = array_keys($row);
                    $updates = array_values(array_filter($columns, static fn ($c) => $c !== 'id'));
                    $sql = $target->dialect()->upsert($table, $columns, ['id'], $updates);
                    $statement = $dst->prepare($sql);
                    $statement->execute($row);
                }
                $targetCount = $dryRun ? count($rows) : (int) $dst->query('SELECT COUNT(*) FROM ' . $table)->fetchColumn();
                $counts[$table] = ['source' => count($rows), 'target' => $targetCount];
                if (!$dryRun && $targetCount !== count($rows)) {
                    throw new RuntimeException("Row count mismatch for {$table}");
                }
            }
            if (!$dryRun) {
                $dst->commit();
            }
        } catch (\Throwable $e) {
            if ($dst->inTransaction()) {
                $dst->rollBack();
            } throw $e;
        }
        return $counts;
    }
}
