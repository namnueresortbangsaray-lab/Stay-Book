CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY, name TEXT NOT NULL, email TEXT NOT NULL UNIQUE, password_hash TEXT NOT NULL,
  role TEXT NOT NULL CHECK(role IN ('admin','front_desk','housekeeping')), active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL, updated_at TEXT NOT NULL, deleted_at TEXT
);
CREATE TABLE IF NOT EXISTS rooms (
  id TEXT PRIMARY KEY, name TEXT NOT NULL UNIQUE, zone TEXT NOT NULL, type TEXT NOT NULL,
  price_satang INTEGER NOT NULL CHECK(price_satang >= 0), base_guests INTEGER NOT NULL CHECK(base_guests >= 1),
  max_guests INTEGER NOT NULL CHECK(max_guests >= base_guests), extra_guest_fee_satang INTEGER NOT NULL DEFAULT 0,
  sort_order INTEGER NOT NULL DEFAULT 0, status INTEGER NOT NULL DEFAULT 0 CHECK(status IN (0,1)),
  is_pet_friendly INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL, updated_at TEXT NOT NULL, deleted_at TEXT
);
CREATE TABLE IF NOT EXISTS guests (
  id TEXT PRIMARY KEY, name TEXT NOT NULL, phone TEXT NOT NULL, normalized_phone TEXT NOT NULL UNIQUE,
  customer_type TEXT NOT NULL DEFAULT 'ลูกค้าทั่วไป', is_regular INTEGER NOT NULL DEFAULT 0,
  customer_note TEXT, preferences TEXT, created_at TEXT NOT NULL, updated_at TEXT NOT NULL, deleted_at TEXT
);
CREATE TABLE IF NOT EXISTS stays (
  id TEXT PRIMARY KEY, guest_id TEXT REFERENCES guests(id), room_id TEXT NOT NULL REFERENCES rooms(id),
  guest_name TEXT NOT NULL, phone TEXT, check_in_date TEXT NOT NULL, check_out_date TEXT NOT NULL,
  guests INTEGER NOT NULL CHECK(guests >= 1), extra_bed INTEGER NOT NULL DEFAULT 0,
  total_amount_satang INTEGER NOT NULL CHECK(total_amount_satang >= 0), status INTEGER NOT NULL DEFAULT 0 CHECK(status IN (0,1,2)),
  note TEXT, deposit_amount_satang INTEGER NOT NULL DEFAULT 0, deposit_paid INTEGER NOT NULL DEFAULT 0,
  id_verified INTEGER NOT NULL DEFAULT 0, pet_type TEXT, pet_count INTEGER NOT NULL DEFAULT 0,
  pet_fee_satang INTEGER NOT NULL DEFAULT 0, discount_amount_satang INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL, updated_at TEXT NOT NULL, deleted_at TEXT,
  CHECK(check_out_date > check_in_date)
);
CREATE TABLE IF NOT EXISTS checkout_inspections (
  id TEXT PRIMARY KEY, stay_id TEXT NOT NULL UNIQUE REFERENCES stays(id) ON DELETE CASCADE,
  key_returned INTEGER NOT NULL, room_clean INTEGER NOT NULL, equipment_complete INTEGER NOT NULL,
  no_damage INTEGER NOT NULL, minibar_checked INTEGER NOT NULL, inspection_note TEXT,
  inspected_by TEXT REFERENCES users(id), inspected_at TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS feedbacks (
  id TEXT PRIMARY KEY, stay_id TEXT NOT NULL UNIQUE REFERENCES stays(id) ON DELETE CASCADE,
  cleanliness_rating INTEGER NOT NULL CHECK(cleanliness_rating BETWEEN 1 AND 5),
  service_rating INTEGER NOT NULL CHECK(service_rating BETWEEN 1 AND 5),
  facility_rating INTEGER NOT NULL CHECK(facility_rating BETWEEN 1 AND 5),
  overall_rating INTEGER NOT NULL CHECK(overall_rating BETWEEN 1 AND 5),
  would_return INTEGER NOT NULL DEFAULT 1, comment TEXT, created_at TEXT NOT NULL, updated_at TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS attachments (
  id TEXT PRIMARY KEY, stay_id TEXT NOT NULL REFERENCES stays(id) ON DELETE CASCADE, uploaded_by TEXT NOT NULL REFERENCES users(id),
  original_name TEXT NOT NULL, stored_name TEXT NOT NULL UNIQUE, mime_type TEXT NOT NULL, size_bytes INTEGER NOT NULL,
  created_at TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS audit_logs (
  id TEXT PRIMARY KEY, user_id TEXT REFERENCES users(id), action TEXT NOT NULL, entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL, before_json TEXT, after_json TEXT, ip_address TEXT, created_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_rooms_zone_status ON rooms(zone,status);
CREATE INDEX IF NOT EXISTS idx_guests_name ON guests(name);
CREATE INDEX IF NOT EXISTS idx_guests_phone ON guests(normalized_phone);
CREATE INDEX IF NOT EXISTS idx_stays_dates ON stays(check_in_date,check_out_date);
CREATE INDEX IF NOT EXISTS idx_stays_room_status ON stays(room_id,status);
CREATE INDEX IF NOT EXISTS idx_stays_guest ON stays(guest_id);
CREATE INDEX IF NOT EXISTS idx_audit_entity ON audit_logs(entity_type,entity_id,created_at);
