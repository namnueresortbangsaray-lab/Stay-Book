// ชั้นติดต่อฐานข้อมูล SQLite ของทั้งแอป
//
// กฎของโปรเจกต์: คำสั่ง SQL ทุกบรรทัดต้องอยู่ในไฟล์นี้ที่เดียว หน้าจอทุกหน้าเรียกผ่าน
// เมธอดของคลาสนี้เท่านั้น ข้อดีคือเวลาโครงสร้างตารางเปลี่ยน จะรู้ทันทีว่าต้องแก้ที่ไหน
// และเวลาไล่หาสาเหตุข้อมูลผิด ก็มีที่ให้ดูแค่ไฟล์เดียว
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../app_state.dart';
import '../models/dashboard_data.dart';
import '../models/room.dart';
import '../models/stay.dart';
import '../utils/formatters.dart';

class DatabaseHelper {
  // สร้างอ็อบเจกต์เดียวใช้ทั้งแอป (Singleton) เพราะการเปิดไฟล์ฐานข้อมูลซ้ำหลายครั้ง
  // จากหลายหน้าจอพร้อมกันอาจทำให้ข้อมูลที่อ่านได้ไม่ตรงกัน
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const String _databaseName = 'stay_book.db';
  static const int _databaseVersion = 1;

  Database? _database;

  /// เปิดฐานข้อมูลครั้งแรกที่ถูกเรียก ครั้งต่อ ๆ ไปคืนตัวเดิมที่เปิดค้างไว้
  Future<Database> get database async {
    _database ??= await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    // getDatabasesPath คืนโฟลเดอร์ข้อมูลส่วนตัวของแอปตามระบบปฏิบัติการ
    // ไฟล์จึงอยู่รอดแม้ปิดแอป และถูกลบไปพร้อมกันเมื่อผู้ใช้ถอนการติดตั้งแอป
    final String folder = await getDatabasesPath();
    return openDatabase(
      p.join(folder, _databaseName),
      version: _databaseVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
    );
  }

  /// SQLite ปิดการบังคับ FOREIGN KEY ไว้เป็นค่าเริ่มต้น ต้องสั่งเปิดเองทุกครั้งที่เปิดฐานข้อมูล
  /// ถ้าไม่เปิด จะบันทึกรายการเข้าพักที่อ้างห้องซึ่งไม่มีอยู่จริงได้ และข้อมูลจะเสียเงียบ ๆ
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// สร้างตารางและใส่ข้อมูลห้อง 15 ห้องให้ตอนเปิดแอปครั้งแรกเท่านั้น
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE rooms (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        name            TEXT    NOT NULL,
        zone            TEXT    NOT NULL,
        type            TEXT    NOT NULL,
        price           REAL    NOT NULL,
        base_guests     INTEGER NOT NULL DEFAULT 2,
        max_guests      INTEGER NOT NULL DEFAULT 2,
        extra_guest_fee REAL    NOT NULL DEFAULT 0,
        status          INTEGER NOT NULL DEFAULT 0,
        sort_order      INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // วันที่ทุกคอลัมน์เก็บเป็น TEXT รูปแบบ yyyy-MM-dd เพราะ SQLite ไม่มีชนิดข้อมูลวันที่
    // รูปแบบนี้เรียงลำดับด้วยการเทียบข้อความแล้วได้ลำดับเวลาที่ถูกต้อง และใช้กับ julianday ได้
    // สังเกตว่าไม่มีคอลัมน์ "จำนวนคืน" เพราะคำนวณจากสองวันนี้ได้เสมอ
    // ถ้าเก็บซ้ำไว้แล้วมีใครแก้วันที่ ตัวเลขที่เก็บจะกลายเป็นข้อมูลผิดที่ไม่มีใครรู้
    await db.execute('''
      CREATE TABLE stays (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        guest_name     TEXT    NOT NULL,
        phone          TEXT,
        room_id        INTEGER NOT NULL,
        check_in_date  TEXT    NOT NULL,
        check_out_date TEXT    NOT NULL,
        guests         INTEGER NOT NULL DEFAULT 1,
        extra_bed      INTEGER NOT NULL DEFAULT 0,
        total_amount   REAL    NOT NULL,
        status         INTEGER NOT NULL DEFAULT 0,
        note           TEXT,
        created_at     TEXT    NOT NULL,
        FOREIGN KEY (room_id) REFERENCES rooms (id)
      )
    ''');

    await _seedRooms(db);
  }

  /// ข้อมูลห้องตั้งต้นของรีสอร์ท 15 ห้อง
  ///
  /// ห้องโซน B ตั้ง base_guests เป็น 4 เพราะเป็นห้องเตียงใหญ่ที่คิดราคาเหมา
  /// พัก 3 หรือ 4 ท่านก็จ่าย 800 เท่ากัน จึงไม่ต้องมีค่าคนเพิ่ม
  Future<void> _seedRooms(Database db) async {
    const List<List<Object>> seed = <List<Object>>[
      // name, zone, type, price, base_guests, max_guests, extra_guest_fee, sort_order
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

    // ใช้ Batch ยิงคำสั่งทีเดียว 15 บรรทัด เร็วกว่าเรียก insert ทีละครั้ง
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
        'status': Room.statusVacant,
        'sort_order': row[7],
      });
    }
    await batch.commit(noResult: true);
  }

  // ---------------------------------------------------------------------------
  // เพิ่มข้อมูล
  // ---------------------------------------------------------------------------

  /// เพิ่มห้องใหม่ คืนค่า id ที่ฐานข้อมูลออกให้
  ///
  /// ถ้าไม่ได้ระบุ sortOrder มาให้ (เป็น 0) จะต่อท้ายรายการเดิมอัตโนมัติ
  /// เพื่อไม่ให้ห้องใหม่ไปแทรกกลางผังห้องแบบไม่มีเหตุผล
  Future<int> insertRoom(Room room) async {
    final Database db = await database;
    Map<String, Object?> values = room.toMap();

    if (room.sortOrder == 0) {
      final int maxOrder = Sqflite.firstIntValue(
            await db.rawQuery('SELECT MAX(sort_order) FROM rooms'),
          ) ??
          0;
      values = <String, Object?>{...values, 'sort_order': maxOrder + 1};
    }

    final int id = await db.insert('rooms', values);
    notifyDbChanged();
    return id;
  }

  /// เปิดรายการเข้าพักใหม่ คืนค่า id ของรายการ
  ///
  /// ต้องใช้ Transaction เพราะกรณี "เช็คอินทันที" ต้องแตะสองตารางคือเพิ่มแถวใน stays
  /// และเปลี่ยน rooms.status เป็นไม่ว่าง ถ้าคำสั่งที่สองพลาดแล้วคำสั่งแรกยังอยู่
  /// จะได้แขกที่เช็คอินแล้วแต่ผังห้องยังขึ้นว่าห้องว่าง แล้วจะมีคนจองซ้อนทับได้
  Future<int> insertStay(Stay stay) async {
    final Database db = await database;
    final int id = await db.transaction<int>((Transaction txn) async {
      final int newId = await txn.insert('stays', stay.toMap());
      if (stay.status == Stay.statusCheckedIn) {
        await txn.update(
          'rooms',
          <String, Object?>{'status': Room.statusOccupied},
          where: 'id = ?',
          whereArgs: <Object?>[stay.roomId],
        );
      }
      return newId;
    });
    notifyDbChanged();
    return id;
  }

  // ---------------------------------------------------------------------------
  // อ่านข้อมูล
  // ---------------------------------------------------------------------------

  /// ดึงห้องทั้งหมดพร้อมข้อมูลแขกที่กำลังพักอยู่ ใช้วาดหน้าผังห้อง
  ///
  /// ต้องใช้ LEFT JOIN ไม่ใช่ INNER JOIN เพราะห้องว่างไม่มีแถวคู่ในตาราง stays
  /// ถ้าใช้ INNER JOIN ห้องว่างทั้งหมดจะหายไปจากผลลัพธ์ ซึ่งผิดวัตถุประสงค์ของหน้านี้
  /// ที่ต้องเห็นครบทุกห้อง
  ///
  /// เงื่อนไข s.status = 1 ต้องวางไว้ใน ON ไม่ใช่ WHERE เพราะถ้าย้ายไป WHERE
  /// แถวของห้องว่างที่ join ไม่ติด (ค่าเป็น NULL) จะถูกกรองทิ้งไปด้วย
  /// กลายเป็นว่า LEFT JOIN ทำงานเหมือน INNER JOIN
  ///
  /// nights_left คำนวณจากผลต่างของเลขวันแบบจูเลียน ระหว่างวันเช็คเอาท์กับวันนี้
  /// ใช้ date('now','localtime') เพื่อให้ได้วันตามเวลาเครื่อง ไม่ใช่เวลามาตรฐาน UTC
  Future<List<RoomWithStay>> getRoomsWithCurrentStay() async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.rawQuery('''
      SELECT r.*,
             s.id            AS stay_id,
             s.guest_name,
             s.check_out_date,
             CAST(julianday(s.check_out_date)
                - julianday(date('now','localtime')) AS INTEGER) AS nights_left
      FROM rooms r
      LEFT JOIN stays s
             ON s.room_id = r.id
            AND s.status = ?
      ORDER BY r.sort_order
    ''', <Object?>[Stay.statusCheckedIn]);

    return rows.map(RoomWithStay.fromMap).toList();
  }

  /// ห้องที่ว่างตลอดช่วงวันที่ระบุ ใช้เติมดรอปดาวน์เลือกห้องในฟอร์มจอง
  ///
  /// ใช้ NOT EXISTS กับเงื่อนไขวันทับซ้อนชุดเดียวกับ hasOverlap
  /// เพื่อให้ดรอปดาวน์กับการตรวจสอบตอนกดบันทึกใช้ตรรกะเดียวกันเป๊ะ ๆ
  /// ไม่มีทางที่ดรอปดาวน์จะโชว์ห้องที่บันทึกไม่ผ่าน
  ///
  /// [excludeStayId] ใส่ตอนแก้ไขรายการเดิม เพื่อไม่ให้รายการนั้นถูกนับว่าชนกับตัวเอง
  Future<List<Room>> getRoomsForBooking(
    String checkInDate,
    String checkOutDate, {
    int? excludeStayId,
  }) async {
    final Database db = await database;
    final String excludeClause = excludeStayId == null ? '' : 'AND s.id != ?';
    final List<Object?> args = <Object?>[
      Stay.statusBooked,
      Stay.statusCheckedIn,
      checkOutDate,
      checkInDate,
      if (excludeStayId != null) excludeStayId,
    ];

    final List<Map<String, Object?>> rows = await db.rawQuery('''
      SELECT r.*
      FROM rooms r
      WHERE NOT EXISTS (
        SELECT 1 FROM stays s
        WHERE s.room_id = r.id
          AND s.status IN (?, ?)
          AND s.check_in_date  < ?
          AND s.check_out_date > ?
          $excludeClause
      )
      ORDER BY r.sort_order
    ''', args);

    return rows.map(Room.fromMap).toList();
  }

  /// ตรวจว่าห้องนี้มีคนจองคาบเกี่ยวกับช่วงวันที่ขอมาหรือไม่
  ///
  /// อ่านเงื่อนไขว่า "ช่วงเวลาสองช่วงทับกัน ก็ต่อเมื่อช่วงเดิมเริ่มก่อนที่ช่วงใหม่จะจบ
  /// และช่วงเดิมจบหลังจากที่ช่วงใหม่เริ่ม" จึงเขียนเป็น
  ///   check_in_date  < วันเช็คเอาท์ที่ขอ  และ
  ///   check_out_date > วันเช็คอินที่ขอ
  ///
  /// ที่ใช้ < และ > ไม่ใช่ <= และ >= เป็นเรื่องสำคัญ เพราะแขกคนเก่าออกตอนเที่ยง
  /// แขกคนใหม่เข้าตอนบ่ายโมงของวันเดียวกันได้ วันที่ต่อกันพอดีจึงไม่นับว่าทับซ้อน
  ///
  /// นับเฉพาะสถานะ 0 กับ 1 เท่านั้น รายการที่เช็คเอาท์ไปแล้ว (2) เป็นประวัติ
  /// ไม่ได้จองห้องไว้อีกต่อไป จึงไม่ควรมาขวางการจองใหม่
  Future<bool> hasOverlap(
    int roomId,
    String checkInDate,
    String checkOutDate, {
    int? excludeStayId,
  }) async {
    final Database db = await database;
    final String excludeClause = excludeStayId == null ? '' : 'AND id != ?';
    final List<Object?> args = <Object?>[
      roomId,
      Stay.statusBooked,
      Stay.statusCheckedIn,
      checkOutDate,
      checkInDate,
      if (excludeStayId != null) excludeStayId,
    ];

    final int count = Sqflite.firstIntValue(await db.rawQuery('''
          SELECT COUNT(*) FROM stays
          WHERE room_id = ?
            AND status IN (?, ?)
            AND check_in_date  < ?
            AND check_out_date > ?
            $excludeClause
        ''', args)) ??
        0;

    return count > 0;
  }

  /// รายการเข้าพักที่ครอบคลุมวันที่ระบุ ใช้กับหน้าตารางเข้าพัก
  ///
  /// เงื่อนไขคือวันที่ที่เลือกต้องอยู่ในช่วง check_in_date ถึงก่อน check_out_date
  /// วันเช็คเอาท์ไม่ถูกนับ เพราะแขกคืนห้องตอนเที่ยงของวันนั้น ไม่ได้นอนคืนนั้นแล้ว
  ///
  /// เรียงตาม s.status ก่อน เพื่อให้คนที่ยังไม่มาเช็คอิน (0) ลอยขึ้นมาอยู่บนสุด
  /// เป็นคิวงานที่พนักงานต้องจัดการ แล้วค่อยเรียงตามลำดับห้อง
  Future<List<StayWithRoom>> getStaysOnDate(String date) async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.rawQuery('''
      SELECT s.*, r.name AS room_name, r.zone
      FROM stays s
      INNER JOIN rooms r ON r.id = s.room_id
      WHERE ? >= s.check_in_date
        AND ? <  s.check_out_date
        AND s.status IN (?, ?)
      ORDER BY s.status, r.sort_order
    ''', <Object?>[date, date, Stay.statusBooked, Stay.statusCheckedIn]);

    return rows.map(StayWithRoom.fromMap).toList();
  }

  /// รายการเข้าพักทั้งหมดรวมที่เช็คเอาท์ไปแล้ว ใช้กับโหมด "ดูประวัติทั้งหมด"
  /// เรียงจากวันเช็คอินล่าสุดลงมา เพราะคนมักอยากเห็นรายการใหม่ก่อน
  Future<List<StayWithRoom>> getAllStays() async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.rawQuery('''
      SELECT s.*, r.name AS room_name, r.zone
      FROM stays s
      INNER JOIN rooms r ON r.id = s.room_id
      ORDER BY s.check_in_date DESC, r.sort_order
    ''');

    return rows.map(StayWithRoom.fromMap).toList();
  }

  /// รายการของแขกที่กำลังพักอยู่ในห้องนี้ คืน null ถ้าห้องว่าง
  /// ใช้ตอนแตะการ์ดห้องไม่ว่างเพื่อเปิดแผ่นข้อมูลด้านล่าง
  Future<StayWithRoom?> getActiveStayOfRoom(int roomId) async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.rawQuery('''
      SELECT s.*, r.name AS room_name, r.zone
      FROM stays s
      INNER JOIN rooms r ON r.id = s.room_id
      WHERE s.room_id = ? AND s.status = ?
      LIMIT 1
    ''', <Object?>[roomId, Stay.statusCheckedIn]);

    if (rows.isEmpty) return null;
    return StayWithRoom.fromMap(rows.first);
  }

  /// ห้องทั้งหมดเรียงตาม sort_order ใช้กับหน้าจัดการห้องพัก
  Future<List<Room>> getAllRooms() async {
    final Database db = await database;
    final List<Map<String, Object?>> rows =
        await db.query('rooms', orderBy: 'sort_order');
    return rows.map(Room.fromMap).toList();
  }

  /// จำนวนรายการเข้าพักที่ผูกกับห้องนี้ ใช้เตือนผู้ใช้ก่อนลบห้องว่าจะเสียประวัติไปเท่าไร
  Future<int> countStaysOfRoom(int roomId) async {
    final Database db = await database;
    return Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM stays WHERE room_id = ?',
            <Object?>[roomId],
          ),
        ) ??
        0;
  }

  /// รวมตัวเลขทุกอย่างของหน้าภาพรวมไว้ในเมธอดเดียว
  ///
  /// จงใจให้หน้าจอเรียกครั้งเดียวได้ครบ เพื่อไม่ให้หน้าจอต้องรู้ว่าตัวเลขแต่ละตัว
  /// มาจากคิวรีแบบไหน และเพื่อให้ทุกตัวเลขบนหน้าเดียวกันอ่านจากฐานข้อมูล ณ จังหวะใกล้กัน
  Future<DashboardData> getDashboard() async {
    final Database db = await database;
    final String today = todayIso();
    // เดือนปัจจุบันในรูปแบบ yyyy-MM ใช้เทียบกับ substr ของวันเช็คอิน
    final String thisMonth = today.substring(0, 7);

    final int totalRooms =
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM rooms')) ?? 0;

    final int occupiedRooms = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM rooms WHERE status = ?',
          <Object?>[Room.statusOccupied],
        )) ??
        0;

    // นับคนที่มีกำหนดเข้าวันนี้และเช็คอินแล้ว รวมถึงคนที่เข้าและออกภายในวันเดียว (สถานะ 2)
    // เพราะทั้งสองกรณีถือว่างานรับแขกของวันนี้เสร็จไปแล้ว
    final int checkedInToday = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM stays WHERE check_in_date = ? AND status IN (?, ?)',
          <Object?>[today, Stay.statusCheckedIn, Stay.statusCheckedOut],
        )) ??
        0;

    final int pendingToday = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM stays WHERE check_in_date = ? AND status = ?',
          <Object?>[today, Stay.statusBooked],
        )) ??
        0;

    // ครบกำหนดออกวันนี้ นับเฉพาะคนที่ยังอยู่ในห้องจริง ๆ (สถานะ 1)
    final int dueOutToday = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM stays WHERE check_out_date = ? AND status = ?',
          <Object?>[today, Stay.statusCheckedIn],
        )) ??
        0;

    // รายรับนับตามวันเช็คอิน และนับเฉพาะรายการที่แขกมาถึงจริงแล้ว
    // การจองที่ยังไม่เช็คอิน (สถานะ 0) ยังไม่ถือเป็นรายรับ เพราะอาจไม่มาก็ได้
    final double revenueToday = _firstDouble(await db.rawQuery(
      'SELECT SUM(total_amount) FROM stays WHERE check_in_date = ? AND status IN (?, ?)',
      <Object?>[today, Stay.statusCheckedIn, Stay.statusCheckedOut],
    ));

    // substr(check_in_date, 1, 7) ตัดเอาเฉพาะส่วน yyyy-MM ออกมาเทียบเดือน
    // ทำแบบนี้ได้เพราะรูปแบบวันที่ในฐานข้อมูลถูกบังคับให้เป็น yyyy-MM-dd เสมอ
    final double revenueMonth = _firstDouble(await db.rawQuery(
      'SELECT SUM(total_amount) FROM stays '
      'WHERE substr(check_in_date, 1, 7) = ? AND status IN (?, ?)',
      <Object?>[thisMonth, Stay.statusCheckedIn, Stay.statusCheckedOut],
    ));

    final List<Map<String, Object?>> pendingRows = await db.rawQuery('''
      SELECT s.*, r.name AS room_name, r.zone
      FROM stays s
      INNER JOIN rooms r ON r.id = s.room_id
      WHERE s.check_in_date = ? AND s.status = ?
      ORDER BY r.sort_order
    ''', <Object?>[today, Stay.statusBooked]);

    return DashboardData(
      totalRooms: totalRooms,
      occupiedRooms: occupiedRooms,
      checkedInToday: checkedInToday,
      pendingToday: pendingToday,
      dueOutToday: dueOutToday,
      revenueToday: revenueToday,
      revenueMonth: revenueMonth,
      pendingArrivals: pendingRows.map(StayWithRoom.fromMap).toList(),
    );
  }

  /// SUM ของ SQLite คืน NULL เมื่อไม่มีแถวที่เข้าเงื่อนไข ไม่ใช่ 0
  /// จึงต้องแปลงเป็น 0 ก่อนส่งให้หน้าจอ ไม่งั้นจะพังตอนที่ยังไม่มีข้อมูลสักรายการ
  double _firstDouble(List<Map<String, Object?>> rows) {
    if (rows.isEmpty) return 0;
    final Object? value = rows.first.values.first;
    return value == null ? 0 : (value as num).toDouble();
  }

  // ---------------------------------------------------------------------------
  // แก้ไขข้อมูล
  // ---------------------------------------------------------------------------

  /// แก้ไขข้อมูลห้อง จงใจไม่แตะคอลัมน์ status
  /// เพราะสถานะว่าง/ไม่ว่างต้องถูกเปลี่ยนโดยการเช็คอินและเช็คเอาท์เท่านั้น
  /// ถ้าปล่อยให้ฟอร์มแก้ไขห้องเขียนทับได้ จะเกิดกรณีห้องกลายเป็นว่างทั้งที่มีแขกนอนอยู่
  Future<void> updateRoom(Room room) async {
    final Database db = await database;
    final Map<String, Object?> values = room.toMap()..remove('status');
    await db.update(
      'rooms',
      values,
      where: 'id = ?',
      whereArgs: <Object?>[room.id],
    );
    notifyDbChanged();
  }

  /// เปลี่ยนรายการจอง (0) เป็นเช็คอินแล้ว (1) และตั้งห้องเป็นไม่ว่าง
  ///
  /// ต้องอยู่ใน Transaction เพราะแตะสองตาราง ถ้าอัปเดต stays สำเร็จแต่ rooms พลาด
  /// ผังห้องจะยังขึ้นว่าห้องว่างทั้งที่มีแขกอยู่ แล้วอาจมีคนเช็คอินซ้ำเข้าห้องเดียวกัน
  /// Transaction ทำให้ถ้าคำสั่งใดพลาด ทุกอย่างย้อนกลับเป็นเหมือนเดิมทั้งหมด
  Future<void> checkIn(int stayId) async {
    final Database db = await database;
    await db.transaction((Transaction txn) async {
      final List<Map<String, Object?>> rows = await txn.query(
        'stays',
        columns: <String>['room_id'],
        where: 'id = ?',
        whereArgs: <Object?>[stayId],
      );
      if (rows.isEmpty) return;

      await txn.update(
        'stays',
        <String, Object?>{'status': Stay.statusCheckedIn},
        where: 'id = ?',
        whereArgs: <Object?>[stayId],
      );
      await txn.update(
        'rooms',
        <String, Object?>{'status': Room.statusOccupied},
        where: 'id = ?',
        whereArgs: <Object?>[rows.first['room_id']],
      );
    });
    notifyDbChanged();
  }

  /// เปลี่ยนรายการเป็นเช็คเอาท์แล้ว (2) และคืนห้องให้กลับเป็นว่าง
  /// เหตุผลที่ต้องใช้ Transaction เหมือน checkIn คือกันไม่ให้ห้องค้างสถานะไม่ว่าง
  /// ทั้งที่แขกกลับไปแล้ว ซึ่งจะทำให้ขายห้องนั้นไม่ได้อีกเลย
  Future<void> checkOut(int stayId) async {
    final Database db = await database;
    await db.transaction((Transaction txn) async {
      final List<Map<String, Object?>> rows = await txn.query(
        'stays',
        columns: <String>['room_id'],
        where: 'id = ?',
        whereArgs: <Object?>[stayId],
      );
      if (rows.isEmpty) return;

      await txn.update(
        'stays',
        <String, Object?>{'status': Stay.statusCheckedOut},
        where: 'id = ?',
        whereArgs: <Object?>[stayId],
      );
      await txn.update(
        'rooms',
        <String, Object?>{'status': Room.statusVacant},
        where: 'id = ?',
        whereArgs: <Object?>[rows.first['room_id']],
      );
    });
    notifyDbChanged();
  }

  // ---------------------------------------------------------------------------
  // ลบข้อมูล
  // ---------------------------------------------------------------------------

  /// ลบรายการเข้าพัก
  ///
  /// ต้องอ่านสถานะเดิมก่อนลบ เพราะถ้ารายการที่ลบกำลังเช็คอินอยู่ (สถานะ 1)
  /// ต้องคืนห้องให้เป็นว่างด้วย ไม่งั้นจะเหลือห้องที่ระบบคิดว่าไม่ว่าง
  /// ทั้งที่ไม่มีรายการเข้าพักไหนอ้างถึงแล้ว และจะไม่มีทางปลดสถานะนั้นได้อีก
  /// การอ่าน การลบ และการคืนสถานะห้องจึงต้องอยู่ใน Transaction เดียวกันทั้งหมด
  Future<void> deleteStay(int stayId) async {
    final Database db = await database;
    await db.transaction((Transaction txn) async {
      final List<Map<String, Object?>> rows = await txn.query(
        'stays',
        columns: <String>['room_id', 'status'],
        where: 'id = ?',
        whereArgs: <Object?>[stayId],
      );
      if (rows.isEmpty) return;

      final int roomId = rows.first['room_id']! as int;
      final int status = rows.first['status']! as int;

      await txn.delete('stays', where: 'id = ?', whereArgs: <Object?>[stayId]);

      if (status == Stay.statusCheckedIn) {
        await txn.update(
          'rooms',
          <String, Object?>{'status': Room.statusVacant},
          where: 'id = ?',
          whereArgs: <Object?>[roomId],
        );
      }
    });
    notifyDbChanged();
  }

  /// ลบห้องพร้อมประวัติการเข้าพักทั้งหมดของห้องนั้น
  ///
  /// ต้องลบแถวในตารางลูก (stays) ก่อนตารางแม่ (rooms) เสมอ เพราะเปิด
  /// PRAGMA foreign_keys ไว้ ถ้าลบห้องทั้งที่ยังมีรายการอ้างถึง ฐานข้อมูลจะปฏิเสธคำสั่ง
  /// และต้องอยู่ใน Transaction เดียวกัน ไม่งั้นถ้าลบ stays สำเร็จแต่ลบห้องพลาด
  /// จะเสียประวัติการเข้าพักไปฟรี ๆ ทั้งที่ห้องยังอยู่
  Future<void> deleteRoom(int roomId) async {
    final Database db = await database;
    await db.transaction((Transaction txn) async {
      await txn.delete('stays', where: 'room_id = ?', whereArgs: <Object?>[roomId]);
      await txn.delete('rooms', where: 'id = ?', whereArgs: <Object?>[roomId]);
    });
    notifyDbChanged();
  }
}
