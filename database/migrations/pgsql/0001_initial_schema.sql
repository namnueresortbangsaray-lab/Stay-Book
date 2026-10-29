CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY, name text NOT NULL, email text NOT NULL UNIQUE, password_hash text NOT NULL,
  role text NOT NULL CHECK(role IN ('admin','front_desk','housekeeping')), active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL, updated_at timestamptz NOT NULL, deleted_at timestamptz
);
CREATE TABLE IF NOT EXISTS rooms (
  id uuid PRIMARY KEY, name text NOT NULL UNIQUE, zone text NOT NULL, type text NOT NULL,
  price_satang bigint NOT NULL CHECK(price_satang >= 0), base_guests integer NOT NULL CHECK(base_guests >= 1),
  max_guests integer NOT NULL CHECK(max_guests >= base_guests), extra_guest_fee_satang bigint NOT NULL DEFAULT 0,
  sort_order integer NOT NULL DEFAULT 0, status integer NOT NULL DEFAULT 0 CHECK(status IN (0,1)),
  is_pet_friendly boolean NOT NULL DEFAULT false, created_at timestamptz NOT NULL, updated_at timestamptz NOT NULL, deleted_at timestamptz
);
CREATE TABLE IF NOT EXISTS guests (
  id uuid PRIMARY KEY, name text NOT NULL, phone text NOT NULL, normalized_phone text NOT NULL UNIQUE,
  customer_type text NOT NULL DEFAULT 'ลูกค้าทั่วไป', is_regular boolean NOT NULL DEFAULT false,
  customer_note text, preferences text, created_at timestamptz NOT NULL, updated_at timestamptz NOT NULL, deleted_at timestamptz
);
CREATE TABLE IF NOT EXISTS stays (
  id uuid PRIMARY KEY, guest_id uuid REFERENCES guests(id), room_id uuid NOT NULL REFERENCES rooms(id),
  guest_name text NOT NULL, phone text, check_in_date date NOT NULL, check_out_date date NOT NULL,
  guests integer NOT NULL CHECK(guests >= 1), extra_bed boolean NOT NULL DEFAULT false,
  total_amount_satang bigint NOT NULL CHECK(total_amount_satang >= 0), status integer NOT NULL DEFAULT 0 CHECK(status IN (0,1,2)),
  note text, deposit_amount_satang bigint NOT NULL DEFAULT 0, deposit_paid boolean NOT NULL DEFAULT false,
  id_verified boolean NOT NULL DEFAULT false, pet_type text, pet_count integer NOT NULL DEFAULT 0,
  pet_fee_satang bigint NOT NULL DEFAULT 0, discount_amount_satang bigint NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL, updated_at timestamptz NOT NULL, deleted_at timestamptz,
  CHECK(check_out_date > check_in_date)
);
CREATE TABLE IF NOT EXISTS checkout_inspections (
  id uuid PRIMARY KEY, stay_id uuid NOT NULL UNIQUE REFERENCES stays(id) ON DELETE CASCADE,
  key_returned boolean NOT NULL, room_clean boolean NOT NULL, equipment_complete boolean NOT NULL,
  no_damage boolean NOT NULL, minibar_checked boolean NOT NULL, inspection_note text,
  inspected_by uuid REFERENCES users(id), inspected_at timestamptz NOT NULL
);
CREATE TABLE IF NOT EXISTS feedbacks (
  id uuid PRIMARY KEY, stay_id uuid NOT NULL UNIQUE REFERENCES stays(id) ON DELETE CASCADE,
  cleanliness_rating integer NOT NULL CHECK(cleanliness_rating BETWEEN 1 AND 5),
  service_rating integer NOT NULL CHECK(service_rating BETWEEN 1 AND 5),
  facility_rating integer NOT NULL CHECK(facility_rating BETWEEN 1 AND 5),
  overall_rating integer NOT NULL CHECK(overall_rating BETWEEN 1 AND 5),
  would_return boolean NOT NULL DEFAULT true, comment text, created_at timestamptz NOT NULL, updated_at timestamptz NOT NULL
);
CREATE TABLE IF NOT EXISTS attachments (
  id uuid PRIMARY KEY, stay_id uuid NOT NULL REFERENCES stays(id) ON DELETE CASCADE, uploaded_by uuid NOT NULL REFERENCES users(id),
  original_name text NOT NULL, stored_name text NOT NULL UNIQUE, mime_type text NOT NULL, size_bytes bigint NOT NULL,
  created_at timestamptz NOT NULL
);
CREATE TABLE IF NOT EXISTS audit_logs (
  id uuid PRIMARY KEY, user_id uuid REFERENCES users(id), action text NOT NULL, entity_type text NOT NULL,
  entity_id uuid NOT NULL, before_json jsonb, after_json jsonb, ip_address text, created_at timestamptz NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_rooms_zone_status ON rooms(zone,status);
CREATE INDEX IF NOT EXISTS idx_guests_name ON guests(name);
CREATE INDEX IF NOT EXISTS idx_guests_phone ON guests(normalized_phone);
CREATE INDEX IF NOT EXISTS idx_stays_dates ON stays(check_in_date,check_out_date);
CREATE INDEX IF NOT EXISTS idx_stays_room_status ON stays(room_id,status);
CREATE INDEX IF NOT EXISTS idx_stays_guest ON stays(guest_id);
CREATE INDEX IF NOT EXISTS idx_audit_entity ON audit_logs(entity_type,entity_id,created_at);
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE guests ENABLE ROW LEVEL SECURITY;
ALTER TABLE stays ENABLE ROW LEVEL SECURITY;
ALTER TABLE checkout_inspections ENABLE ROW LEVEL SECURITY;
ALTER TABLE feedbacks ENABLE ROW LEVEL SECURITY;
ALTER TABLE attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE schema_migrations ENABLE ROW LEVEL SECURITY;
