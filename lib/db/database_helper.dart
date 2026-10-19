// ศูนย์กลาง SQLite ของแอป รวม schema, migration และคำสั่งข้อมูลไว้ไฟล์เดียว
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../app_state.dart';
import '../models/analytics.dart';
import '../models/checkout_inspection.dart';
import '../models/dashboard_data.dart';
import '../models/guest.dart';
import '../models/room.dart';
import '../models/stay.dart';
import '../utils/formatters.dart';

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static const String _databaseName = 'stay_book.db';
  static const int _databaseVersion = 2;
  Database? _database;

  Future<Database> get database async => _database ??= await _openDatabase();
  Future<Database> _openDatabase() async => openDatabase(
    p.join(await getDatabasesPath(), _databaseName),
    version: _databaseVersion,
    onConfigure: (Database db) => db.execute('PRAGMA foreign_keys = ON'),
    onCreate: _onCreate,
    onUpgrade: _onUpgrade,
  );

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''CREATE TABLE rooms (
      id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, zone TEXT NOT NULL,
      type TEXT NOT NULL, price REAL NOT NULL, base_guests INTEGER NOT NULL DEFAULT 2,
      max_guests INTEGER NOT NULL DEFAULT 2, extra_guest_fee REAL NOT NULL DEFAULT 0,
      status INTEGER NOT NULL DEFAULT 0, sort_order INTEGER NOT NULL DEFAULT 0,
      is_pet_friendly INTEGER NOT NULL DEFAULT 0)''');
    await db.execute('''CREATE TABLE guests (
      id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, phone TEXT NOT NULL,
      normalized_phone TEXT NOT NULL UNIQUE, customer_type TEXT NOT NULL DEFAULT 'ลูกค้าทั่วไป',
      is_regular INTEGER NOT NULL DEFAULT 0, customer_note TEXT, preferences TEXT,
      created_at TEXT NOT NULL, updated_at TEXT NOT NULL)''');
    await db.execute(
      '''CREATE TABLE stays (
      id INTEGER PRIMARY KEY AUTOINCREMENT, guest_name TEXT NOT NULL, phone TEXT,
      room_id INTEGER NOT NULL, check_in_date TEXT NOT NULL, check_out_date TEXT NOT NULL,
      guests INTEGER NOT NULL DEFAULT 1, extra_bed INTEGER NOT NULL DEFAULT 0,
      total_amount REAL NOT NULL, status INTEGER NOT NULL DEFAULT 0, note TEXT,
      created_at TEXT NOT NULL, guest_id INTEGER, deposit_amount REAL NOT NULL DEFAULT 0,
      deposit_paid INTEGER NOT NULL DEFAULT 0, id_verified INTEGER NOT NULL DEFAULT 0,
      pet_type TEXT, pet_count INTEGER NOT NULL DEFAULT 0, pet_fee REAL NOT NULL DEFAULT 0,
      discount_amount REAL NOT NULL DEFAULT 0,
      FOREIGN KEY (room_id) REFERENCES rooms(id), FOREIGN KEY (guest_id) REFERENCES guests(id))''',
    );
    await _createSupportTables(db);
    await _seedRooms(db);
  }

  Future<void> _createSupportTables(Database db) async {
    await db.execute(
      '''CREATE TABLE IF NOT EXISTS checkout_inspections (
      id INTEGER PRIMARY KEY AUTOINCREMENT, stay_id INTEGER NOT NULL UNIQUE,
      key_returned INTEGER NOT NULL DEFAULT 0, room_clean INTEGER NOT NULL DEFAULT 0,
      equipment_complete INTEGER NOT NULL DEFAULT 0, no_damage INTEGER NOT NULL DEFAULT 0,
      minibar_checked INTEGER NOT NULL DEFAULT 0, inspection_note TEXT,
      inspected_at TEXT NOT NULL, FOREIGN KEY (stay_id) REFERENCES stays(id))''',
    );
    await db.execute('''CREATE TABLE IF NOT EXISTS feedbacks (
      id INTEGER PRIMARY KEY AUTOINCREMENT, stay_id INTEGER NOT NULL UNIQUE,
      cleanliness_rating INTEGER NOT NULL, service_rating INTEGER NOT NULL,
      facility_rating INTEGER NOT NULL, overall_rating INTEGER NOT NULL,
      would_return INTEGER NOT NULL DEFAULT 1, comment TEXT, created_at TEXT NOT NULL,
      FOREIGN KEY (stay_id) REFERENCES stays(id))''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // สร้างตารางแม่ก่อนเพิ่ม foreign key เพื่อให้ migration ทำงานได้เหมือนกันทุกแพลตฟอร์ม
      await db.execute('''CREATE TABLE guests (
        id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, phone TEXT NOT NULL,
        normalized_phone TEXT NOT NULL UNIQUE, customer_type TEXT NOT NULL DEFAULT 'ลูกค้าทั่วไป',
        is_regular INTEGER NOT NULL DEFAULT 0, customer_note TEXT, preferences TEXT,
        created_at TEXT NOT NULL, updated_at TEXT NOT NULL)''');
      await db.execute(
        'ALTER TABLE rooms ADD COLUMN is_pet_friendly INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE stays ADD COLUMN guest_id INTEGER REFERENCES guests(id)',
      );
      await db.execute(
        'ALTER TABLE stays ADD COLUMN deposit_amount REAL NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE stays ADD COLUMN deposit_paid INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE stays ADD COLUMN id_verified INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute('ALTER TABLE stays ADD COLUMN pet_type TEXT');
      await db.execute(
        'ALTER TABLE stays ADD COLUMN pet_count INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE stays ADD COLUMN pet_fee REAL NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE stays ADD COLUMN discount_amount REAL NOT NULL DEFAULT 0',
      );
      await _createSupportTables(db);
      await _migrateGuests(db);
    }
  }

  Future<void> _migrateGuests(Database db) async {
    final List<Map<String, Object?>> old = await db.query(
      'stays',
      columns: <String>['id', 'guest_name', 'phone', 'created_at'],
      where: "phone IS NOT NULL AND TRIM(phone) != ''",
      orderBy: 'created_at ASC',
    );
    for (final Map<String, Object?> row in old) {
      final String phone = row['phone'] as String;
      final String normalized = normalizePhone(phone);
      if (normalized.length < 9) continue;
      final String now =
          row['created_at'] as String? ?? DateTime.now().toIso8601String();
      await db.insert('guests', <String, Object?>{
        'name': row['guest_name'],
        'phone': phone,
        'normalized_phone': normalized,
        'created_at': now,
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      final List<Map<String, Object?>> guest = await db.query(
        'guests',
        columns: <String>['id'],
        where: 'normalized_phone = ?',
        whereArgs: <Object>[normalized],
        limit: 1,
      );
      if (guest.isNotEmpty) {
        await db.update(
          'stays',
          <String, Object?>{'guest_id': guest.first['id']},
          where: 'id = ?',
          whereArgs: <Object?>[row['id']],
        );
      }
    }
  }

  Future<void> _seedRooms(Database db) async {
    const List<List<Object>> seed = <List<Object>>[
      <Object>['1', 'อาคารหลัก', 'เตียงคู่', 500.0, 2, 3, 100.0, 1],
      <Object>['2', 'อาคารหลัก', 'เตียงคู่', 500.0, 2, 3, 100.0, 2],
      <Object>['3', 'อาคารหลัก', 'เตียงคู่', 500.0, 2, 3, 100.0, 3],
      <Object>['4', 'อาคารหลัก', 'เตียงคู่', 500.0, 2, 3, 100.0, 4],
      <Object>['5', 'อาคารหลัก', 'เตียงคู่', 500.0, 2, 3, 100.0, 5],
      <Object>['6', 'อาคารหลัก', 'เตียงเดี่ยว', 400.0, 2, 2, 0.0, 6],
      <Object>['7', 'อาคารหลัก', 'เตียงเดี่ยว', 400.0, 2, 2, 0.0, 7],
      <Object>['8', 'อาคารหลัก', 'เตียงเดี่ยว', 400.0, 2, 2, 0.0, 8],
      <Object>['9', 'อาคารหลัก', 'เตียงเดี่ยว', 400.0, 2, 2, 0.0, 9],
      <Object>['10', 'อาคารหลัก', 'เตียงเดี่ยว', 400.0, 2, 2, 0.0, 10],
      <Object>['B1', 'โซน B', 'เตียงใหญ่', 800.0, 4, 4, 0.0, 11],
      <Object>['B2', 'โซน B', 'เตียงใหญ่', 800.0, 4, 4, 0.0, 12],
      <Object>['C1', 'โซน C', 'มินิมอล', 600.0, 2, 2, 0.0, 13],
      <Object>['C2', 'โซน C', 'มินิมอล', 600.0, 2, 2, 0.0, 14],
      <Object>['C3', 'โซน C', 'มินิมอล', 600.0, 2, 2, 0.0, 15],
    ];
    final Batch batch = db.batch();
    for (final List<Object> row in seed) {
      batch.insert('rooms', <String, Object?>{
        'name': row[0],
        'zone': row[1],
        'type': row[2],
        'price': row[3],
        'base_guests': row[4],
        'max_guests': row[5],
        'extra_guest_fee': row[6],
        'sort_order': row[7],
        'status': 0,
        'is_pet_friendly': (row[7] as int) >= 13 ? 1 : 0,
      });
    }
    await batch.commit(noResult: true);
  }

  static const String _stayJoin = '''SELECT s.*, r.name AS room_name, r.zone,
    g.customer_type, g.is_regular, f.overall_rating AS feedback_rating
    FROM stays s JOIN rooms r ON r.id = s.room_id
    LEFT JOIN guests g ON g.id = s.guest_id
    LEFT JOIN feedbacks f ON f.stay_id = s.id''';

  Future<int> insertRoom(Room room) async {
    final Database db = await database;
    final Map<String, Object?> values = room.toMap();
    if (room.sortOrder == 0) {
      values['sort_order'] =
          (Sqflite.firstIntValue(
                await db.rawQuery('SELECT MAX(sort_order) FROM rooms'),
              ) ??
              0) +
          1;
    }
    final int id = await db.insert('rooms', values);
    notifyDbChanged();
    return id;
  }

  Future<void> updateRoom(Room room) async {
    await (await database).update(
      'rooms',
      room.toMap(),
      where: 'id = ?',
      whereArgs: <Object?>[room.id],
    );
    notifyDbChanged();
  }

  Future<List<Room>> getAllRooms() async => (await (await database).query(
    'rooms',
    orderBy: 'sort_order, name',
  )).map(Room.fromMap).toList();
  Future<int> countStaysOfRoom(int roomId) async =>
      Sqflite.firstIntValue(
        await (await database).rawQuery(
          'SELECT COUNT(*) FROM stays WHERE room_id = ?',
          <Object>[roomId],
        ),
      ) ??
      0;

  Future<void> deleteRoom(int roomId) async {
    final Database db = await database;
    await db.transaction((Transaction txn) async {
      await txn.delete(
        'feedbacks',
        where: 'stay_id IN (SELECT id FROM stays WHERE room_id = ?)',
        whereArgs: <Object>[roomId],
      );
      await txn.delete(
        'checkout_inspections',
        where: 'stay_id IN (SELECT id FROM stays WHERE room_id = ?)',
        whereArgs: <Object>[roomId],
      );
      await txn.delete(
        'stays',
        where: 'room_id = ?',
        whereArgs: <Object>[roomId],
      );
      await txn.delete('rooms', where: 'id = ?', whereArgs: <Object>[roomId]);
    });
    notifyDbChanged();
  }

  Future<List<RoomWithStay>> getRoomsWithCurrentStay() async {
    final rows = await (await database).rawQuery(
      '''SELECT r.*, s.id AS stay_id, s.guest_name, s.check_out_date,
      CAST(julianday(s.check_out_date)-julianday(date('now','localtime')) AS INTEGER) nights_left
      FROM rooms r LEFT JOIN stays s ON s.room_id=r.id AND s.status=1 ORDER BY r.sort_order,r.name''',
    );
    return rows.map(RoomWithStay.fromMap).toList();
  }

  Future<List<Room>> getRoomsForBooking(
    String checkIn,
    String checkOut, {
    int? excludeStayId,
    bool petFriendlyOnly = false,
  }) async {
    final List<Object?> args = <Object?>[checkOut, checkIn];
    String exclude = '';
    if (excludeStayId != null) {
      exclude = 'AND s.id != ?';
      args.add(excludeStayId);
    }
    final String pet = petFriendlyOnly ? 'AND r.is_pet_friendly = 1' : '';
    final rows = await (await database).rawQuery(
      '''SELECT r.* FROM rooms r WHERE NOT EXISTS
      (SELECT 1 FROM stays s WHERE s.room_id=r.id AND s.status IN (0,1)
      AND s.check_in_date < ? AND s.check_out_date > ? $exclude) $pet ORDER BY r.sort_order,r.name''',
      args,
    );
    return rows.map(Room.fromMap).toList();
  }

  Future<bool> hasOverlap(
    int roomId,
    String checkIn,
    String checkOut, {
    int? excludeStayId,
  }) async {
    final List<Object?> args = <Object?>[roomId, checkOut, checkIn];
    String exclude = '';
    if (excludeStayId != null) {
      exclude = 'AND id != ?';
      args.add(excludeStayId);
    }
    return (Sqflite.firstIntValue(
              await (await database).rawQuery(
                '''SELECT COUNT(*) FROM stays WHERE room_id=?
      AND status IN (0,1) AND check_in_date < ? AND check_out_date > ? $exclude''',
                args,
              ),
            ) ??
            0) >
        0;
  }

  Future<int> insertStay(Stay stay) async {
    final id = await (await database).insert('stays', stay.toMap());
    notifyDbChanged();
    return id;
  }

  Future<int> createStayWithGuest(Stay stay) async {
    final Database db = await database;
    final int id = await db.transaction((Transaction txn) async {
      int? guestId = stay.guestId;
      final String normalized = normalizePhone(stay.phone ?? '');
      if (guestId == null && normalized.length >= 9) {
        final found = await txn.query(
          'guests',
          where: 'normalized_phone = ?',
          whereArgs: <Object>[normalized],
          limit: 1,
        );
        if (found.isEmpty) {
          final String now = DateTime.now().toIso8601String();
          guestId = await txn.insert('guests', <String, Object?>{
            'name': stay.guestName,
            'phone': stay.phone ?? '',
            'normalized_phone': normalized,
            'created_at': now,
            'updated_at': now,
          });
        } else {
          guestId = found.first['id'] as int;
        }
      }
      if (stay.status == Stay.statusCheckedIn && !stay.idVerified) {
        throw StateError('ต้องตรวจสอบบัตรประชาชนก่อนเช็กอินทันที');
      }
      final int stayId = await txn.insert(
        'stays',
        stay.copyWith(guestId: guestId).toMap(),
      );
      if (stay.status == Stay.statusCheckedIn) {
        final int occupied =
            Sqflite.firstIntValue(
              await txn.rawQuery(
                'SELECT COUNT(*) FROM stays WHERE room_id = ? AND status = 1 AND id != ?',
                <Object>[stay.roomId, stayId],
              ),
            ) ??
            0;
        if (occupied > 0) {
          throw StateError('ห้องนี้มีผู้เข้าพักอยู่แล้ว');
        }
        await txn.update(
          'rooms',
          <String, Object?>{'status': 1},
          where: 'id = ?',
          whereArgs: <Object>[stay.roomId],
        );
      }
      return stayId;
    });
    notifyDbChanged();
    return id;
  }

  Future<void> updateStay(Stay stay) async {
    await (await database).update(
      'stays',
      stay.toMap(),
      where: 'id = ?',
      whereArgs: <Object?>[stay.id],
    );
    notifyDbChanged();
  }

  Future<List<StayWithRoom>> getAllStays() => searchStays();
  Future<List<StayWithRoom>> getStaysOnDate(String date) async {
    final rows = await (await database).rawQuery(
      '$_stayJoin WHERE s.check_in_date <= ? AND s.check_out_date >= ? ORDER BY s.check_in_date,r.sort_order',
      <Object>[date, date],
    );
    return rows.map(StayWithRoom.fromMap).toList();
  }

  /// โหลดรายการที่แตะช่วงเดือน ใช้ครั้งเดียวแล้วกระจายลงแต่ละช่องปฏิทินบนหน้าจอ
  /// รวมวันเช็กเอาต์ไว้ด้วยเพื่อให้พนักงานเห็นงานคืนห้องในวันนั้น
  Future<List<StayWithRoom>> getStaysForMonth(int year, int month) async {
    final DateTime firstDay = DateTime(year, month);
    final DateTime nextMonth = DateTime(year, month + 1);
    final List<Map<String, Object?>> rows = await (await database).rawQuery(
      '''$_stayJoin WHERE s.check_in_date < ? AND s.check_out_date >= ?
         ORDER BY s.check_in_date, r.sort_order''',
      <Object>[toIsoDate(nextMonth), toIsoDate(firstDay)],
    );
    return rows.map(StayWithRoom.fromMap).toList();
  }

  Future<List<StayWithRoom>> searchStays({
    String keyword = '',
    int? status,
  }) async {
    final List<Object?> args = <Object?>[];
    final List<String> clauses = <String>[];
    if (status != null) {
      clauses.add('s.status = ?');
      args.add(status);
    }
    if (keyword.trim().isNotEmpty) {
      final t = '%${keyword.trim()}%';
      clauses.add(
        '(s.guest_name LIKE ? OR s.phone LIKE ? OR r.name LIKE ? OR r.zone LIKE ? OR s.note LIKE ?)',
      );
      args.addAll(<Object>[t, t, t, t, t]);
    }
    final String where = clauses.isEmpty
        ? ''
        : 'WHERE ${clauses.join(' AND ')}';
    final rows = await (await database).rawQuery(
      '$_stayJoin $where ORDER BY s.created_at DESC',
      args,
    );
    return rows.map(StayWithRoom.fromMap).toList();
  }

  Future<StayWithRoom?> getActiveStayOfRoom(int roomId) async {
    final rows = await (await database).rawQuery(
      '$_stayJoin WHERE s.room_id=? AND s.status=1 LIMIT 1',
      <Object>[roomId],
    );
    return rows.isEmpty ? null : StayWithRoom.fromMap(rows.first);
  }

  Future<void> checkIn(int stayId) async {
    final Database db = await database;
    await db.transaction((Transaction txn) async {
      final rows = await txn.query(
        'stays',
        where: 'id = ?',
        whereArgs: <Object>[stayId],
        limit: 1,
      );
      if (rows.isEmpty) throw StateError('ไม่พบรายการเข้าพัก');
      final Stay stay = Stay.fromMap(rows.first);
      if (stay.status != Stay.statusBooked) {
        throw StateError('รายการนี้ไม่ได้อยู่ในสถานะรอเช็กอิน');
      }
      if (!stay.idVerified) {
        throw StateError('ต้องยืนยันว่าตรวจสอบบัตรประชาชนแล้วก่อนเช็กอิน');
      }
      final int occupied =
          Sqflite.firstIntValue(
            await txn.rawQuery(
              'SELECT COUNT(*) FROM stays WHERE room_id=? AND status=1 AND id!=?',
              <Object>[stay.roomId, stayId],
            ),
          ) ??
          0;
      if (occupied > 0) throw StateError('ห้องนี้มีผู้เข้าพักอยู่แล้ว');
      final int conflict =
          Sqflite.firstIntValue(
            await txn.rawQuery(
              '''SELECT COUNT(*) FROM stays WHERE room_id = ? AND status IN (0,1)
                 AND id != ? AND check_in_date < ? AND check_out_date > ?''',
              <Object>[
                stay.roomId,
                stayId,
                stay.checkOutDate,
                stay.checkInDate,
              ],
            ),
          ) ??
          0;
      if (conflict > 0) {
        throw StateError('ช่วงเข้าพักชนกับ Booking อื่น');
      }
      await txn.update(
        'stays',
        <String, Object?>{'status': 1},
        where: 'id = ?',
        whereArgs: <Object>[stayId],
      );
      await txn.update(
        'rooms',
        <String, Object?>{'status': 1},
        where: 'id = ?',
        whereArgs: <Object>[stay.roomId],
      );
    });
    notifyDbChanged();
  }

  Future<void> extendStay(Stay stay) async {
    if (await hasOverlap(
      stay.roomId,
      stay.checkInDate,
      stay.checkOutDate,
      excludeStayId: stay.id,
    )) {
      throw StateError('วันที่ใหม่ชนกับรายการจองถัดไปของห้องนี้');
    }
    await (await database).transaction(
      (txn) => txn.update(
        'stays',
        <String, Object?>{
          'check_out_date': stay.checkOutDate,
          'total_amount': stay.totalAmount,
          'pet_fee': stay.petFee,
          'discount_amount': stay.discountAmount,
        },
        where: 'id = ?',
        whereArgs: <Object?>[stay.id],
      ),
    );
    notifyDbChanged();
  }

  Future<void> checkOutWithInspection(CheckoutInspection value) async {
    // หน้าจอบังคับให้ตอบครบทุกข้อก่อนสร้าง model ส่วนค่า false เป็นคำตอบที่ถูกต้อง
    // และต้องถูกเก็บไว้เพื่อให้ตรวจสอบย้อนหลังได้ จึงไม่บังคับว่าทุกคำตอบต้องเป็น true
    if (!value.noDamage && (value.inspectionNote ?? '').trim().isEmpty) {
      throw StateError('กรุณาระบุรายละเอียดความเสียหาย');
    }
    final Database db = await database;
    await db.transaction((Transaction txn) async {
      final rows = await txn.query(
        'stays',
        columns: <String>['room_id', 'status'],
        where: 'id = ?',
        whereArgs: <Object>[value.stayId],
        limit: 1,
      );
      if (rows.isEmpty || rows.first['status'] != 1) {
        throw StateError('รายการนี้ไม่อยู่ในสถานะกำลังเข้าพัก');
      }
      await txn.insert(
        'checkout_inspections',
        value.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.update(
        'stays',
        <String, Object?>{'status': 2},
        where: 'id = ?',
        whereArgs: <Object>[value.stayId],
      );
      await txn.update(
        'rooms',
        <String, Object?>{'status': 0},
        where: 'id = ?',
        whereArgs: <Object?>[rows.first['room_id']],
      );
    });
    notifyDbChanged();
  }

  Future<void> checkOut(int stayId) => checkOutWithInspection(
    CheckoutInspection(
      stayId: stayId,
      keyReturned: true,
      roomClean: true,
      equipmentComplete: true,
      noDamage: true,
      minibarChecked: true,
      inspectedAt: DateTime.now().toIso8601String(),
    ),
  );
  Future<void> deleteStay(int stayId) async {
    final Database db = await database;
    await db.transaction((Transaction txn) async {
      final rows = await txn.query(
        'stays',
        columns: <String>['room_id', 'status'],
        where: 'id = ?',
        whereArgs: <Object>[stayId],
        limit: 1,
      );
      await txn.delete(
        'feedbacks',
        where: 'stay_id = ?',
        whereArgs: <Object>[stayId],
      );
      await txn.delete(
        'checkout_inspections',
        where: 'stay_id = ?',
        whereArgs: <Object>[stayId],
      );
      await txn.delete('stays', where: 'id = ?', whereArgs: <Object>[stayId]);
      if (rows.isNotEmpty && rows.first['status'] == 1) {
        await txn.update(
          'rooms',
          <String, Object?>{'status': 0},
          where: 'id = ?',
          whereArgs: <Object?>[rows.first['room_id']],
        );
      }
    });
    notifyDbChanged();
  }

  Future<Guest?> findGuestByPhone(String phone) async {
    final normalized = normalizePhone(phone);
    if (normalized.length < 9) return null;
    final rows = await (await database).query(
      'guests',
      where: 'normalized_phone = ?',
      whereArgs: <Object>[normalized],
      limit: 1,
    );
    return rows.isEmpty ? null : Guest.fromMap(rows.first);
  }

  Future<int> insertGuest(Guest value) async {
    final id = await (await database).insert('guests', value.toMap());
    notifyDbChanged();
    return id;
  }

  Future<void> updateGuest(Guest value) async {
    await (await database).update(
      'guests',
      value.toMap(),
      where: 'id = ?',
      whereArgs: <Object?>[value.id],
    );
    notifyDbChanged();
  }

  Future<List<GuestSummary>> searchGuests({
    String keyword = '',
    bool regularOnly = false,
    String? customerType,
    String sort = 'latest',
  }) async {
    final List<Object?> args = <Object?>[];
    final List<String> clauses = <String>[];
    if (keyword.trim().isNotEmpty) {
      final t = '%${keyword.trim()}%';
      clauses.add('(g.name LIKE ? OR g.phone LIKE ?)');
      args.addAll(<Object>[t, t]);
    }
    if (regularOnly) clauses.add('g.is_regular=1');
    if (customerType != null && customerType.isNotEmpty) {
      clauses.add('g.customer_type=?');
      args.add(customerType);
    }
    const orders = <String, String>{
      'latest': 'last_stay_date DESC',
      'count': 'completed_stays DESC',
      'value': 'lifetime_value DESC',
      'name': 'g.name COLLATE NOCASE',
    };
    final String where = clauses.isEmpty
        ? ''
        : 'WHERE ${clauses.join(' AND ')}';
    final rows = await (await database).rawQuery(
      '''SELECT g.*,
      SUM(CASE WHEN s.status=2 THEN 1 ELSE 0 END) completed_stays,
      COALESCE(SUM(CASE WHEN s.status=2 THEN CAST(julianday(s.check_out_date)-julianday(s.check_in_date) AS INTEGER) ELSE 0 END),0) total_nights,
      COALESCE(SUM(CASE WHEN s.status=2 THEN s.total_amount ELSE 0 END),0) lifetime_value,
      COALESCE(SUM(CASE WHEN s.status=2 THEN s.discount_amount ELSE 0 END),0) total_discount,
      MAX(s.check_in_date) last_stay_date,
      (SELECT r2.name FROM stays s2 JOIN rooms r2 ON r2.id=s2.room_id WHERE s2.guest_id=g.id ORDER BY s2.check_in_date DESC LIMIT 1) last_room_name
      FROM guests g LEFT JOIN stays s ON s.guest_id=g.id $where GROUP BY g.id ORDER BY ${orders[sort] ?? orders['latest']}''',
      args,
    );
    return rows.map(GuestSummary.fromMap).toList();
  }

  Future<GuestHistory> getGuestHistory(int guestId) async {
    final summaries = await searchGuests();
    final summary = summaries.firstWhere((e) => e.guest.id == guestId);
    final rows = await (await database).rawQuery(
      '$_stayJoin WHERE s.guest_id=? ORDER BY s.check_in_date DESC',
      <Object>[guestId],
    );
    return GuestHistory(
      summary: summary,
      stays: rows.map(StayWithRoom.fromMap).toList(),
    );
  }

  Future<int> getCompletedStayCountOfGuest(int id) async =>
      (await getGuestHistory(id)).summary.completedStays;
  Future<double> getGuestLifetimeValue(int id) async =>
      (await getGuestHistory(id)).summary.lifetimeValue;
  Future<CheckoutInspection?> getInspectionByStayId(int id) async {
    final r = await (await database).query(
      'checkout_inspections',
      where: 'stay_id=?',
      whereArgs: <Object>[id],
      limit: 1,
    );
    return r.isEmpty ? null : CheckoutInspection.fromMap(r.first);
  }

  Future<GuestFeedback?> getFeedbackByStayId(int id) async {
    final r = await (await database).query(
      'feedbacks',
      where: 'stay_id=?',
      whereArgs: <Object>[id],
      limit: 1,
    );
    return r.isEmpty ? null : GuestFeedback.fromMap(r.first);
  }

  Future<int> insertFeedback(GuestFeedback value) async {
    final Database db = await database;
    final int completed =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM stays WHERE id = ? AND status = 2',
            <Object>[value.stayId],
          ),
        ) ??
        0;
    if (completed == 0) {
      throw StateError('บันทึก Feedback ได้หลังเช็กเอาต์เท่านั้น');
    }
    final id = await db.insert(
      'feedbacks',
      value.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    notifyDbChanged();
    return id;
  }

  Future<void> updateFeedback(GuestFeedback value) async {
    await (await database).update(
      'feedbacks',
      value.toMap(),
      where: 'stay_id=?',
      whereArgs: <Object>[value.stayId],
    );
    notifyDbChanged();
  }

  Future<DashboardRangeData> getDashboardByDateRange(
    String start,
    String end,
  ) async {
    final Database db = await database;
    final int totalRooms =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM rooms'),
        ) ??
        0;
    final raw = await db.query(
      'stays',
      where: 'check_in_date <= ? AND check_out_date > ?',
      whereArgs: <Object>[end, start],
    );
    final stays = raw.map(Stay.fromMap).toList();
    final List<DailyRevenue> revenues = [];
    final List<DailyOccupancy> occupancies = [];
    int roomNights = 0;
    DateTime day = DateTime.parse(start);
    final last = DateTime.parse(end);
    while (!day.isAfter(last)) {
      final iso = toIsoDate(day);
      final present = stays
          .where(
            (s) =>
                s.checkInDate.compareTo(iso) <= 0 &&
                s.checkOutDate.compareTo(iso) > 0,
          )
          .length;
      final amount = stays
          .where((s) => s.checkInDate == iso && s.status != 0)
          .fold<double>(0, (a, s) => a + s.totalAmount);
      revenues.add(DailyRevenue(iso, amount));
      occupancies.add(DailyOccupancy(iso, present, totalRooms));
      roomNights += present;
      day = day.add(const Duration(days: 1));
    }
    final started = stays
        .where(
          (s) =>
              s.checkInDate.compareTo(start) >= 0 &&
              s.checkInDate.compareTo(end) <= 0,
        )
        .toList();
    final billable = started
        .where((Stay stay) => stay.status != Stay.statusBooked)
        .toList();
    final feedback = await db.rawQuery(
      'SELECT AVG(f.overall_rating) average FROM feedbacks f JOIN stays s ON s.id=f.stay_id WHERE s.check_in_date BETWEEN ? AND ?',
      <Object>[start, end],
    );
    int booked = 0, inside = 0, out = 0, none = 0, paid = 0, unpaid = 0;
    for (final s in started) {
      if (s.status == 0) {
        booked++;
      } else if (s.status == 1) {
        inside++;
      } else {
        out++;
      }
      if (s.depositAmount == 0) {
        none++;
      } else if (s.depositPaid) {
        paid++;
      } else {
        unpaid++;
      }
    }
    return DashboardRangeData(
      startDate: start,
      endDate: end,
      totalRooms: totalRooms,
      bookingCount: started.length,
      checkInCount: started.where((s) => s.status >= 1).length,
      checkOutCount: out,
      guestCount: started.fold<int>(0, (a, s) => a + s.guests),
      occupiedRoomNights: roomNights,
      grossRevenue: billable.fold<double>(0, (a, s) => a + s.grossAmount),
      totalDiscount: billable.fold<double>(0, (a, s) => a + s.discountAmount),
      netRevenue: billable.fold<double>(0, (a, s) => a + s.totalAmount),
      depositReceived: started
          .where((s) => s.depositPaid)
          .fold<double>(0, (a, s) => a + s.depositAmount),
      depositPending: started
          .where((s) => !s.depositPaid)
          .fold<double>(0, (a, s) => a + s.depositAmount),
      petBookings: started.where((s) => s.hasPet).length,
      averageFeedback: (feedback.first['average'] as num?)?.toDouble() ?? 0,
      revenueChart: revenues,
      occupancyChart: occupancies,
      bookingStatuses: BookingStatusSummary(
        booked: booked,
        checkedIn: inside,
        checkedOut: out,
      ),
      depositStatuses: DepositSummary(none: none, paid: paid, unpaid: unpaid),
    );
  }

  Future<List<DailyRevenue>> getRevenueChart(String start, String end) async =>
      (await getDashboardByDateRange(start, end)).revenueChart;
  Future<List<DailyOccupancy>> getOccupancyChart(
    String start,
    String end,
  ) async => (await getDashboardByDateRange(start, end)).occupancyChart;
  Future<DashboardData> getDashboard() async {
    final today = todayIso();
    final range = await getDashboardByDateRange(today, today);
    final pending = (await searchStays(
      status: 0,
    )).where((e) => e.stay.checkInDate == today).toList();
    final occupied =
        Sqflite.firstIntValue(
          await (await database).rawQuery(
            'SELECT COUNT(*) FROM rooms WHERE status=1',
          ),
        ) ??
        0;
    final due =
        Sqflite.firstIntValue(
          await (await database).rawQuery(
            'SELECT COUNT(*) FROM stays WHERE status=1 AND check_out_date=?',
            <Object>[today],
          ),
        ) ??
        0;
    final now = DateTime.now();
    final month = await getDashboardByDateRange(
      toIsoDate(DateTime(now.year, now.month, 1)),
      today,
    );
    return DashboardData(
      totalRooms: range.totalRooms,
      occupiedRooms: occupied,
      checkedInToday: range.checkInCount,
      pendingToday: pending.length,
      dueOutToday: due,
      revenueToday: range.netRevenue,
      revenueMonth: month.netRevenue,
      pendingArrivals: pending,
    );
  }
}
