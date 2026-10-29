<?php

declare(strict_types=1);

namespace App\Repositories\Database;

use App\Database\Connection;
use App\Repositories\Contracts\ResortRepositoryInterface;
use App\Support\Date;
use App\Support\Str;
use App\Support\Uuid;
use PDO;
use RuntimeException;

final class ResortRepository implements ResortRepositoryInterface
{
    private PDO $db;

    public function __construct(private readonly Connection $connection)
    {
        $this->db = $connection->pdo();
    }

    public function findUserByEmail(string $email): ?array
    {
        $s = $this->db->prepare('SELECT * FROM users WHERE email = :email AND active = :active AND deleted_at IS NULL');
        $s->execute(['email' => strtolower(trim($email)), 'active' => $this->connection->dialect()->boolean(true)]);
        return $s->fetch() ?: null;
    }

    public function createUser(array $data): void
    {
        $sql = 'INSERT INTO users(id,name,email,password_hash,role,active,created_at,updated_at) VALUES(:id,:name,:email,:password_hash,:role,:active,:created_at,:updated_at)';
        $this->db->prepare($sql)->execute($data + ['active' => $this->connection->dialect()->boolean(true)]);
    }

    public function rooms(): array
    {
        $rows = $this->db->query('SELECT * FROM rooms WHERE deleted_at IS NULL ORDER BY zone,sort_order,name')->fetchAll();
        return array_map(fn (array $r) => $this->normalizeRoom($r), $rows);
    }

    public function saveRoom(array $data, ?string $id = null): array
    {
        $now = Date::now();
        if ($id === null) {
            $id = Uuid::make();
            $sql = 'INSERT INTO rooms(id,name,zone,type,price_satang,base_guests,max_guests,extra_guest_fee_satang,sort_order,status,is_pet_friendly,created_at,updated_at) VALUES(:id,:name,:zone,:type,:price_satang,:base_guests,:max_guests,:extra_guest_fee_satang,:sort_order,:status,:is_pet_friendly,:created_at,:updated_at)';
            $this->db->prepare($sql)->execute($data + ['id' => $id, 'status' => 0, 'created_at' => $now, 'updated_at' => $now]);
        } else {
            $sql = 'UPDATE rooms SET name=:name,zone=:zone,type=:type,price_satang=:price_satang,base_guests=:base_guests,max_guests=:max_guests,extra_guest_fee_satang=:extra_guest_fee_satang,sort_order=:sort_order,is_pet_friendly=:is_pet_friendly,updated_at=:updated_at WHERE id=:id AND deleted_at IS NULL';
            $this->db->prepare($sql)->execute($data + ['id' => $id, 'updated_at' => $now]);
        }
        return $this->find('rooms', $id, 'normalizeRoom');
    }

    public function deleteRoom(string $id): void
    {
        $s = $this->db->prepare('SELECT COUNT(*) FROM stays WHERE room_id=:id AND deleted_at IS NULL');
        $s->execute(['id' => $id]);
        if ((int) $s->fetchColumn() > 0) {
            $this->db->beginTransaction();
            try {
                $ids = $this->db->prepare('SELECT id FROM stays WHERE room_id=:id');
                $ids->execute(['id' => $id]);
                foreach ($ids->fetchAll(PDO::FETCH_COLUMN) as $stayId) {
                    $this->db->prepare('DELETE FROM feedbacks WHERE stay_id=:id')->execute(['id' => $stayId]);
                    $this->db->prepare('DELETE FROM checkout_inspections WHERE stay_id=:id')->execute(['id' => $stayId]);
                    $this->db->prepare('DELETE FROM attachments WHERE stay_id=:id')->execute(['id' => $stayId]);
                }
                $this->db->prepare('DELETE FROM stays WHERE room_id=:id')->execute(['id' => $id]);
                $this->db->prepare('DELETE FROM rooms WHERE id=:id')->execute(['id' => $id]);
                $this->db->commit();
            } catch (\Throwable $e) {
                if ($this->db->inTransaction()) {
                    $this->db->rollBack();
                }
                throw $e;
            }
            return;
        }
        $this->db->prepare('DELETE FROM rooms WHERE id=:id')->execute(['id' => $id]);
    }

    public function guests(): array
    {
        $sql = 'SELECT g.*,s.id AS stay_id,s.check_in_date,s.check_out_date,s.status AS stay_status,s.total_amount_satang,s.discount_amount_satang,r.name AS room_name FROM guests g LEFT JOIN stays s ON s.guest_id=g.id AND s.deleted_at IS NULL LEFT JOIN rooms r ON r.id=s.room_id WHERE g.deleted_at IS NULL ORDER BY g.updated_at DESC';
        $grouped = [];
        foreach ($this->db->query($sql)->fetchAll() as $row) {
            $id = (string) $row['id'];
            if (!isset($grouped[$id])) {
                $grouped[$id] = $this->normalizeGuest($row) + ['completed_stays' => 0, 'total_nights' => 0, 'lifetime_value_satang' => 0, 'total_discount_satang' => 0, 'last_stay_date' => null, 'last_room_name' => null];
            }
            if ($row['stay_id'] !== null) {
                if ($grouped[$id]['last_stay_date'] === null || $row['check_in_date'] > $grouped[$id]['last_stay_date']) {
                    $grouped[$id]['last_stay_date'] = $row['check_in_date'];
                    $grouped[$id]['last_room_name'] = $row['room_name'];
                }
                if ((int) $row['stay_status'] === 2) {
                    $grouped[$id]['completed_stays']++;
                    $grouped[$id]['total_nights'] += Date::nights((string) $row['check_in_date'], (string) $row['check_out_date']);
                    $grouped[$id]['lifetime_value_satang'] += (int) $row['total_amount_satang'];
                    $grouped[$id]['total_discount_satang'] += (int) $row['discount_amount_satang'];
                }
            }
        }
        return array_values($grouped);
    }

    public function guest(string $id): ?array
    {
        $g = $this->findNullable('guests', $id);
        if ($g === null) {
            return null;
        }
        $summary = null;
        foreach ($this->guests() as $item) {
            if ($item['id'] === $id) {
                $summary = $item;
            }
        }
        return ($summary ?? $this->normalizeGuest($g)) + ['stays' => array_values(array_filter($this->stays(), static fn ($s) => $s['guest_id'] === $id))];
    }

    public function findGuestByPhone(string $phone): ?array
    {
        $s = $this->db->prepare('SELECT * FROM guests WHERE normalized_phone=:phone AND deleted_at IS NULL');
        $s->execute(['phone' => Str::phone($phone)]);
        $row = $s->fetch();
        return $row ? $this->normalizeGuest($row) : null;
    }

    public function saveGuest(array $data, ?string $id = null): array
    {
        $now = Date::now();
        if ($id === null) {
            $id = Uuid::make();
            $sql = 'INSERT INTO guests(id,name,phone,normalized_phone,customer_type,is_regular,customer_note,preferences,created_at,updated_at) VALUES(:id,:name,:phone,:normalized_phone,:customer_type,:is_regular,:customer_note,:preferences,:created_at,:updated_at)';
            $this->db->prepare($sql)->execute($data + ['id' => $id, 'created_at' => $now, 'updated_at' => $now]);
        } else {
            $sql = 'UPDATE guests SET name=:name,phone=:phone,normalized_phone=:normalized_phone,customer_type=:customer_type,is_regular=:is_regular,customer_note=:customer_note,preferences=:preferences,updated_at=:updated_at WHERE id=:id AND deleted_at IS NULL';
            $this->db->prepare($sql)->execute($data + ['id' => $id, 'updated_at' => $now]);
        }
        return $this->find('guests', $id, 'normalizeGuest');
    }

    public function stays(): array
    {
        $sql = 'SELECT s.*,r.name AS room_name,r.zone,r.type AS room_type,r.price_satang AS room_rate_satang,r.base_guests,r.max_guests,r.extra_guest_fee_satang,r.is_pet_friendly,g.customer_type,g.is_regular,f.overall_rating AS feedback_rating FROM stays s JOIN rooms r ON r.id=s.room_id LEFT JOIN guests g ON g.id=s.guest_id LEFT JOIN feedbacks f ON f.stay_id=s.id WHERE s.deleted_at IS NULL ORDER BY s.check_in_date DESC,s.created_at DESC';
        return array_map(fn (array $r) => $this->normalizeStay($r), $this->db->query($sql)->fetchAll());
    }

    public function searchStays(string $search = '', ?int $status = null): array
    {
        $sql = 'SELECT s.*,r.name AS room_name,r.zone,r.type AS room_type,r.price_satang AS room_rate_satang,r.base_guests,r.max_guests,r.extra_guest_fee_satang,r.is_pet_friendly,g.customer_type,g.is_regular,f.overall_rating AS feedback_rating FROM stays s JOIN rooms r ON r.id=s.room_id LEFT JOIN guests g ON g.id=s.guest_id LEFT JOIN feedbacks f ON f.stay_id=s.id WHERE s.deleted_at IS NULL';
        $params = [];
        if ($search !== '') {
            $searches = [];
            foreach (['s.guest_name', 's.phone', 'r.name', 'r.zone', 's.note'] as $index => $column) {
                $parameter = 'search' . $index;
                $searches[] = $this->connection->dialect()->search($column, ':' . $parameter);
                $params[$parameter] = '%' . trim($search) . '%';
            }
            $sql .= ' AND (' . implode(' OR ', $searches) . ')';
        }
        if ($status !== null) {
            $sql .= ' AND s.status=:status';
            $params['status'] = $status;
        }
        $sql .= ' ORDER BY s.check_in_date DESC,s.created_at DESC';
        $statement = $this->db->prepare($sql);
        $statement->execute($params);
        return array_map(fn (array $row) => $this->normalizeStay($row), $statement->fetchAll());
    }

    public function stay(string $id): ?array
    {
        foreach ($this->stays() as $stay) {
            if ($stay['id'] === $id) {
                return $stay;
            }
        }
        return null;
    }

    public function hasOverlap(string $roomId, string $from, string $to, ?string $except = null): bool
    {
        $sql = 'SELECT COUNT(*) FROM stays WHERE room_id=:room AND status IN (0,1) AND deleted_at IS NULL AND check_in_date < :checkout AND check_out_date > :checkin';
        $params = ['room' => $roomId, 'checkout' => $to, 'checkin' => $from];
        if ($except !== null) {
            $sql .= ' AND id<>:except';
            $params['except'] = $except;
        }
        $s = $this->db->prepare($sql);
        $s->execute($params);
        return (int) $s->fetchColumn() > 0;
    }

    public function saveStay(array $data, ?string $id = null): array
    {
        $now = Date::now();
        $this->db->beginTransaction();
        try {
            if ($id === null) {
                $id = Uuid::make();
                $columns = ['id','guest_id','room_id','guest_name','phone','check_in_date','check_out_date','guests','extra_bed','total_amount_satang','status','note','deposit_amount_satang','deposit_paid','id_verified','pet_type','pet_count','pet_fee_satang','discount_amount_satang','created_at','updated_at'];
                $sql = 'INSERT INTO stays(' . implode(',', $columns) . ') VALUES(' . implode(',', array_map(static fn ($c) => ':' . $c, $columns)) . ')';
                $this->db->prepare($sql)->execute($data + ['id' => $id, 'created_at' => $now, 'updated_at' => $now]);
            } else {
                $sets = ['guest_id','room_id','guest_name','phone','check_in_date','check_out_date','guests','extra_bed','total_amount_satang','status','note','deposit_amount_satang','deposit_paid','id_verified','pet_type','pet_count','pet_fee_satang','discount_amount_satang'];
                $sql = 'UPDATE stays SET ' . implode(',', array_map(static fn ($c) => $c . '=:' . $c, $sets)) . ',updated_at=:updated_at WHERE id=:id AND deleted_at IS NULL';
                $this->db->prepare($sql)->execute($data + ['id' => $id, 'updated_at' => $now]);
            }
            if ((int) $data['status'] === 1) {
                $this->db->prepare('UPDATE rooms SET status=1,updated_at=:at WHERE id=:id')->execute(['at' => $now, 'id' => $data['room_id']]);
            }
            $this->db->commit();
        } catch (\Throwable $e) {
            if ($this->db->inTransaction()) {
                $this->db->rollBack();
            } throw $e;
        }
        return $this->stay($id) ?? throw new RuntimeException('Stay not found after save.');
    }

    public function setStayStatus(string $id, int $status, string $userId, array $inspection = []): array
    {
        $stay = $this->stay($id) ?? throw new RuntimeException('ไม่พบ Booking');
        $this->db->beginTransaction();
        try {
            $this->db->prepare('UPDATE stays SET status=:status,updated_at=:at WHERE id=:id')->execute(['status' => $status, 'at' => Date::now(), 'id' => $id]);
            $roomStatus = $status === 1 ? 1 : 0;
            $this->db->prepare('UPDATE rooms SET status=:status,updated_at=:at WHERE id=:id')->execute(['status' => $roomStatus, 'at' => Date::now(), 'id' => $stay['room_id']]);
            if ($status === 2) {
                $this->db->prepare('DELETE FROM checkout_inspections WHERE stay_id=:id')->execute(['id' => $id]);
                $sql = 'INSERT INTO checkout_inspections(id,stay_id,key_returned,room_clean,equipment_complete,no_damage,minibar_checked,inspection_note,inspected_by,inspected_at) VALUES(:id,:stay_id,:key_returned,:room_clean,:equipment_complete,:no_damage,:minibar_checked,:inspection_note,:inspected_by,:inspected_at)';
                $this->db->prepare($sql)->execute($inspection + ['id' => Uuid::make(), 'stay_id' => $id, 'inspected_by' => $userId, 'inspected_at' => Date::now()]);
            }
            $this->db->commit();
        } catch (\Throwable $e) {
            if ($this->db->inTransaction()) {
                $this->db->rollBack();
            } throw $e;
        }
        return $this->stay($id);
    }

    public function deleteStay(string $id, string $userId): void
    {
        $stay = $this->stay($id);
        if ($stay === null) {
            return;
        }
        $this->db->beginTransaction();
        try {
            foreach (['feedbacks','checkout_inspections','attachments'] as $table) {
                $this->db->prepare("DELETE FROM {$table} WHERE stay_id=:id")->execute(['id' => $id]);
            }
            $this->db->prepare('DELETE FROM stays WHERE id=:id')->execute(['id' => $id]);
            if ((int) $stay['status'] === 1) {
                $this->db->prepare('UPDATE rooms SET status=0,updated_at=:at WHERE id=:id')->execute(['at' => Date::now(), 'id' => $stay['room_id']]);
            }
            $this->db->commit();
        } catch (\Throwable $e) {
            if ($this->db->inTransaction()) {
                $this->db->rollBack();
            } throw $e;
        }
    }

    public function saveFeedback(string $stayId, array $data): array
    {
        $existing = $this->db->prepare('SELECT id FROM feedbacks WHERE stay_id=:id');
        $existing->execute(['id' => $stayId]);
        $id = $existing->fetchColumn();
        if ($id) {
            $sql = 'UPDATE feedbacks SET cleanliness_rating=:cleanliness_rating,service_rating=:service_rating,facility_rating=:facility_rating,overall_rating=:overall_rating,would_return=:would_return,comment=:comment,updated_at=:updated_at WHERE stay_id=:stay_id';
            $this->db->prepare($sql)->execute($data + ['stay_id' => $stayId, 'updated_at' => Date::now()]);
        } else {
            $id = Uuid::make();
            $sql = 'INSERT INTO feedbacks(id,stay_id,cleanliness_rating,service_rating,facility_rating,overall_rating,would_return,comment,created_at,updated_at) VALUES(:id,:stay_id,:cleanliness_rating,:service_rating,:facility_rating,:overall_rating,:would_return,:comment,:created_at,:updated_at)';
            $this->db->prepare($sql)->execute($data + ['id' => $id, 'stay_id' => $stayId, 'created_at' => Date::now(), 'updated_at' => Date::now()]);
        }
        $s = $this->db->prepare('SELECT * FROM feedbacks WHERE id=:id');
        $s->execute(['id' => $id]);
        return $this->normalizeBooleans($s->fetch() ?: [], ['would_return']);
    }

    public function saveAttachment(array $data): array
    {
        $sql = 'INSERT INTO attachments(id,stay_id,uploaded_by,original_name,stored_name,mime_type,size_bytes,created_at) VALUES(:id,:stay_id,:uploaded_by,:original_name,:stored_name,:mime_type,:size_bytes,:created_at)';
        $this->db->prepare($sql)->execute($data);
        return $data;
    }

    public function attachment(string $id): ?array
    {
        return $this->findNullable('attachments', $id);
    }

    public function attachments(?string $stayId = null): array
    {
        $sql = 'SELECT id,stay_id,original_name,mime_type,size_bytes,created_at FROM attachments';
        $params = [];
        if ($stayId !== null) {
            $sql .= ' WHERE stay_id=:stay_id';
            $params['stay_id'] = $stayId;
        }
        $sql .= ' ORDER BY created_at DESC';
        $statement = $this->db->prepare($sql);
        $statement->execute($params);
        return $statement->fetchAll();
    }

    public function audit(string $action, string $type, string $id, ?array $before, ?array $after, ?string $userId, string $ip): void
    {
        $sql = 'INSERT INTO audit_logs(id,user_id,action,entity_type,entity_id,before_json,after_json,ip_address,created_at) VALUES(:id,:user_id,:action,:entity_type,:entity_id,:before_json,:after_json,:ip_address,:created_at)';
        $this->db->prepare($sql)->execute(['id' => Uuid::make(), 'user_id' => $userId, 'action' => $action, 'entity_type' => $type, 'entity_id' => $id, 'before_json' => $before ? json_encode($before, JSON_UNESCAPED_UNICODE) : null, 'after_json' => $after ? json_encode($after, JSON_UNESCAPED_UNICODE) : null, 'ip_address' => $ip, 'created_at' => Date::now()]);
    }

    private function find(string $table, string $id, string $normalizer): array
    {
        $row = $this->findNullable($table, $id) ?? throw new RuntimeException("Record not found in {$table}.");
        return $this->{$normalizer}($row);
    }

    private function findNullable(string $table, string $id): ?array
    {
        if (!in_array($table, ['rooms','guests','attachments'], true)) {
            throw new RuntimeException('Invalid table.');
        }
        $s = $this->db->prepare("SELECT * FROM {$table} WHERE id=:id");
        $s->execute(['id' => $id]);
        return $s->fetch() ?: null;
    }

    private function normalizeRoom(array $r): array
    {
        return $this->normalizeBooleans($r, ['is_pet_friendly']);
    }
    private function normalizeGuest(array $r): array
    {
        return $this->normalizeBooleans($r, ['is_regular']);
    }
    private function normalizeStay(array $r): array
    {
        return $this->normalizeBooleans($r, ['extra_bed','deposit_paid','id_verified','is_pet_friendly','is_regular']);
    }
    private function normalizeBooleans(array $r, array $keys): array
    {
        foreach ($keys as $key) {
            if (array_key_exists($key, $r)) {
                $r[$key] = filter_var($r[$key], FILTER_VALIDATE_BOOLEAN);
            }
        } return $r;
    }
}
