// โครงสร้างข้อมูลของห้องพัก และของห้องพักที่พ่วงข้อมูลแขกคนปัจจุบันมาด้วย
// ใช้แปลงแถวข้อมูลดิบจาก sqflite (Map) ให้กลายเป็นอ็อบเจกต์ที่หน้าจอเรียกใช้ได้ปลอดภัย

/// หนึ่งห้องพักในระบบ
class Room {
  /// สถานะห้อง 0 = ว่าง ไม่มีแขกอยู่ในห้องตอนนี้
  static const int statusVacant = 0;

  /// สถานะห้อง 1 = มีผู้เข้าพัก คือมีรายการที่เช็คอินแล้วผูกอยู่กับห้องนี้
  static const int statusOccupied = 1;

  /// null เมื่อยังไม่ถูกบันทึกลงฐานข้อมูล ฐานข้อมูลจะออกเลขให้เองตอน insert
  final int? id;

  /// ชื่อหรือเลขห้องที่ใช้เรียกกัน เช่น 1, B2, C3
  final String name;

  /// โซนของห้อง ใช้จัดกลุ่มในหน้าผังห้อง เช่น อาคารหลัก โซน B
  final String zone;

  /// ประเภทห้อง เช่น เตียงคู่ เตียงเดี่ยว ใช้แสดงให้พนักงานเลือกห้องได้ถูก
  final String type;

  /// ราคาต่อคืน สำหรับผู้เข้าพักไม่เกิน baseGuests คน
  final double price;

  /// จำนวนผู้เข้าพักที่ราคาปกติครอบคลุมอยู่แล้ว เกินจากนี้จึงคิดค่าคนเพิ่ม
  final int baseGuests;

  /// จำนวนผู้เข้าพักสูงสุดที่ห้องรับได้ ใช้จำกัดปุ่มเพิ่มจำนวนคนในฟอร์ม
  final int maxGuests;

  /// ค่าคนเพิ่มต่อคนต่อคืน คิดเฉพาะส่วนที่เกิน baseGuests
  final double extraGuestFee;

  /// ค่าจาก statusVacant หรือ statusOccupied
  final int status;

  /// ลำดับการแสดงผล จำเป็นต้องมีเพราะชื่อห้องเป็นข้อความ
  /// ถ้าเรียงตามชื่อแบบตัวอักษร ห้อง "10" จะไปแทรกอยู่หลังห้อง "1" ทันที
  final int sortOrder;

  const Room({
    this.id,
    required this.name,
    required this.zone,
    required this.type,
    required this.price,
    required this.baseGuests,
    required this.maxGuests,
    required this.extraGuestFee,
    this.status = statusVacant,
    this.sortOrder = 0,
  });

  bool get isOccupied => status == statusOccupied;

  factory Room.fromMap(Map<String, Object?> map) => Room(
        id: map['id'] as int?,
        name: map['name'] as String,
        zone: map['zone'] as String,
        type: map['type'] as String,
        price: (map['price'] as num).toDouble(),
        baseGuests: map['base_guests'] as int,
        maxGuests: map['max_guests'] as int,
        extraGuestFee: (map['extra_guest_fee'] as num).toDouble(),
        status: map['status'] as int,
        sortOrder: map['sort_order'] as int,
      );

  /// แปลงกลับเป็น Map เพื่อส่งให้ sqflite โดยไม่ใส่ id
  /// ปล่อยให้ฐานข้อมูลจัดการเลขที่ระบุแถวเองทั้งตอนเพิ่มและตอนแก้ไข
  Map<String, Object?> toMap() => <String, Object?>{
        'name': name,
        'zone': zone,
        'type': type,
        'price': price,
        'base_guests': baseGuests,
        'max_guests': maxGuests,
        'extra_guest_fee': extraGuestFee,
        'status': status,
        'sort_order': sortOrder,
      };

  Room copyWith({
    int? id,
    String? name,
    String? zone,
    String? type,
    double? price,
    int? baseGuests,
    int? maxGuests,
    double? extraGuestFee,
    int? status,
    int? sortOrder,
  }) =>
      Room(
        id: id ?? this.id,
        name: name ?? this.name,
        zone: zone ?? this.zone,
        type: type ?? this.type,
        price: price ?? this.price,
        baseGuests: baseGuests ?? this.baseGuests,
        maxGuests: maxGuests ?? this.maxGuests,
        extraGuestFee: extraGuestFee ?? this.extraGuestFee,
        status: status ?? this.status,
        sortOrder: sortOrder ?? this.sortOrder,
      );
}

/// ห้องพักหนึ่งห้องพร้อมข้อมูลแขกที่กำลังพักอยู่ (ถ้ามี)
///
/// ใช้กับหน้าผังห้องที่ต้องแสดงทั้งห้องว่างและห้องไม่ว่างในตารางเดียวกัน
/// ฟิลด์ที่มาจากตาราง stays จึงเป็น null ได้ทั้งหมด เพราะห้องว่างไม่มีแขกคู่กัน
class RoomWithStay {
  final Room room;

  /// เลขที่รายการเข้าพักที่กำลังเช็คอินอยู่ เป็น null แปลว่าห้องว่าง
  final int? stayId;
  final String? guestName;

  /// วันเช็คเอาท์ของแขกคนปัจจุบัน รูปแบบ yyyy-MM-dd
  final String? checkOutDate;

  /// จำนวนคืนที่เหลือนับจากวันนี้ ค่า 0 แปลว่าต้องคืนห้องวันนี้
  final int? nightsLeft;

  const RoomWithStay({
    required this.room,
    this.stayId,
    this.guestName,
    this.checkOutDate,
    this.nightsLeft,
  });

  /// ห้องนี้มีแขกอยู่จริงหรือไม่ ดูจากการมีรายการเข้าพักที่เช็คอินแล้ว
  /// ไม่ดูจาก rooms.status เพียงอย่างเดียว เพื่อไม่ให้แสดงว่า "ไม่ว่าง" ทั้งที่ไม่มีชื่อแขก
  bool get isOccupied => stayId != null;

  factory RoomWithStay.fromMap(Map<String, Object?> map) => RoomWithStay(
        room: Room.fromMap(map),
        stayId: map['stay_id'] as int?,
        guestName: map['guest_name'] as String?,
        checkOutDate: map['check_out_date'] as String?,
        nightsLeft: map['nights_left'] as int?,
      );
}
