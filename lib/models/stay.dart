// โครงสร้างข้อมูลของรายการเข้าพัก และสูตรคิดเงินของทั้งระบบ
//
// สูตรคิดเงินถูกรวมไว้ที่คลาส PriceBreakdown ที่เดียว ทั้งฟอร์มจองและการบันทึกลง
// ฐานข้อมูลจึงใช้ตรรกะชุดเดียวกัน ไม่มีทางคิดเงินไม่ตรงกันระหว่างจอกับข้อมูลที่บันทึกจริง
import '../config.dart';
import '../utils/formatters.dart';
import 'room.dart';

/// หนึ่งรายการเข้าพัก ตั้งแต่จองล่วงหน้าจนถึงเช็คเอาท์แล้ว
class Stay {
  /// สถานะ 0 = จองไว้แล้วแต่ยังไม่มาเช็คอิน ห้องยังนับว่าว่างอยู่
  static const int statusBooked = 0;

  /// สถานะ 1 = เช็คอินแล้ว แขกอยู่ในห้อง ห้องจะถูกตั้งเป็นไม่ว่างคู่กันเสมอ
  static const int statusCheckedIn = 1;

  /// สถานะ 2 = เช็คเอาท์แล้ว เก็บไว้เป็นประวัติและใช้คิดรายรับ
  static const int statusCheckedOut = 2;

  final int? id;
  final String guestName;
  final String? phone;
  final int roomId;

  /// วันเช็คอิน รูปแบบ yyyy-MM-dd
  final String checkInDate;

  /// วันเช็คเอาท์ รูปแบบ yyyy-MM-dd (เป็นวันที่ออก ไม่นับเป็นคืนที่พัก)
  final String checkOutDate;

  final int guests;

  /// 0 หรือ 1 เพราะ SQLite ไม่มีชนิดข้อมูลบูลีน จึงเก็บเป็นจำนวนเต็ม
  final int extraBed;

  /// ยอดรวมที่คิดไว้ตอนเปิดรายการ เก็บค่าที่คำนวณแล้วเพื่อให้ประวัติย้อนหลัง
  /// ไม่เปลี่ยนตามราคาห้องที่อาจถูกแก้ในภายหลัง
  final double totalAmount;

  final int status;
  final String? note;

  /// เวลาที่สร้างรายการ เก็บเป็น ISO 8601 ใช้อ้างอิงตอนตรวจสอบย้อนหลัง
  final String createdAt;

  const Stay({
    this.id,
    required this.guestName,
    this.phone,
    required this.roomId,
    required this.checkInDate,
    required this.checkOutDate,
    required this.guests,
    required this.extraBed,
    required this.totalAmount,
    required this.status,
    this.note,
    required this.createdAt,
  });

  bool get hasExtraBed => extraBed == 1;

  /// จำนวนคืนคำนวณจากวันที่ทุกครั้ง ไม่เก็บเป็นคอลัมน์ในฐานข้อมูล
  /// เพราะถ้าเก็บไว้แล้วมีการแก้วันเข้าพัก ค่าที่เก็บจะกลายเป็นข้อมูลผิดทันที
  int get nights => nightsBetween(checkInDate, checkOutDate);

  factory Stay.fromMap(Map<String, Object?> map) => Stay(
        id: map['id'] as int?,
        guestName: map['guest_name'] as String,
        phone: map['phone'] as String?,
        roomId: map['room_id'] as int,
        checkInDate: map['check_in_date'] as String,
        checkOutDate: map['check_out_date'] as String,
        guests: map['guests'] as int,
        extraBed: map['extra_bed'] as int,
        totalAmount: (map['total_amount'] as num).toDouble(),
        status: map['status'] as int,
        note: map['note'] as String?,
        createdAt: map['created_at'] as String,
      );

  Map<String, Object?> toMap() => <String, Object?>{
        'guest_name': guestName,
        'phone': phone,
        'room_id': roomId,
        'check_in_date': checkInDate,
        'check_out_date': checkOutDate,
        'guests': guests,
        'extra_bed': extraBed,
        'total_amount': totalAmount,
        'status': status,
        'note': note,
        'created_at': createdAt,
      };
}

/// รายการเข้าพักที่พ่วงชื่อห้องกับโซนมาด้วย
/// ใช้กับหน้าจอที่ต้องแสดงว่าแขกอยู่ห้องไหน โดยไม่ต้องยิงคิวรีถามชื่อห้องซ้ำทีละรายการ
class StayWithRoom {
  final Stay stay;
  final String roomName;
  final String zone;

  const StayWithRoom({
    required this.stay,
    required this.roomName,
    required this.zone,
  });

  factory StayWithRoom.fromMap(Map<String, Object?> map) => StayWithRoom(
        stay: Stay.fromMap(map),
        roomName: map['room_name'] as String,
        zone: map['zone'] as String,
      );
}

/// รายละเอียดการคิดเงินแยกเป็นบรรทัด ๆ
///
/// สูตร:
///   ยอดรวม = (ราคาห้อง + ค่าคนเพิ่ม x จำนวนคนที่เกิน) x จำนวนคืน + ค่าเตียงเสริม
///
/// จุดสำคัญ: ค่าเตียงเสริมอยู่นอกวงเล็บ จึง **ไม่คูณจำนวนคืน** เพราะรีสอร์ทคิด
/// ค่าเตียงเสริมเป็นค่าบริการครั้งเดียวตอนยกเตียงเข้าห้อง ไม่ได้คิดเป็นรายคืน
/// ส่วนค่าคนเพิ่มคูณจำนวนคืน เพราะเป็นค่าที่พักของคนเพิ่มในแต่ละคืน
class PriceBreakdown {
  final int nights;
  final double roomRate;
  final int extraGuests;
  final double extraGuestFee;
  final bool extraBed;
  final double extraBedFee;

  const PriceBreakdown({
    required this.nights,
    required this.roomRate,
    required this.extraGuests,
    required this.extraGuestFee,
    required this.extraBed,
    required this.extraBedFee,
  });

  double get roomTotal => roomRate * nights;
  double get extraGuestTotal => extraGuestFee * extraGuests * nights;
  double get extraBedTotal => extraBed ? extraBedFee : 0;
  double get total => roomTotal + extraGuestTotal + extraBedTotal;

  /// คิดยอดจากห้อง จำนวนคน ช่วงวันที่ และการขอเตียงเสริม
  factory PriceBreakdown.calculate({
    required Room room,
    required int guests,
    required String checkInDate,
    required String checkOutDate,
    required bool extraBed,
  }) {
    // ต้องครอบด้วยค่าต่ำสุด 0 เผื่อผู้ใช้กรอกจำนวนคนน้อยกว่าที่ราคาห้องครอบคลุม
    // ถ้าไม่ครอบ ค่าคนเพิ่มจะติดลบและไปหักยอดรวมจนเงินผิด
    final int extraGuests =
        (guests - room.baseGuests) > 0 ? guests - room.baseGuests : 0;

    return PriceBreakdown(
      nights: nightsBetween(checkInDate, checkOutDate),
      roomRate: room.price,
      extraGuests: extraGuests,
      extraGuestFee: room.extraGuestFee,
      extraBed: extraBed,
      extraBedFee: ResortConfig.extraBedFee,
    );
  }
}
