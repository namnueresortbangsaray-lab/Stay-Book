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
  final int? guestId;
  final double depositAmount;
  final bool depositPaid;
  final bool idVerified;
  final String? petType;
  final int petCount;
  final double petFee;
  final double discountAmount;

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
    this.guestId,
    this.depositAmount = 0,
    this.depositPaid = false,
    this.idVerified = false,
    this.petType,
    this.petCount = 0,
    this.petFee = 0,
    this.discountAmount = 0,
  });

  bool get hasExtraBed => extraBed == 1;

  /// จำนวนคืนคำนวณจากวันที่ทุกครั้ง ไม่เก็บเป็นคอลัมน์ในฐานข้อมูล
  /// เพราะถ้าเก็บไว้แล้วมีการแก้วันเข้าพัก ค่าที่เก็บจะกลายเป็นข้อมูลผิดทันที
  int get nights => nightsBetween(checkInDate, checkOutDate);

  double get grossAmount => totalAmount + discountAmount;
  double get paidDeposit => depositPaid ? depositAmount : 0;
  double get balanceDue =>
      (totalAmount - paidDeposit).clamp(0, double.infinity);
  bool get hasPet => petCount > 0;

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
    guestId: map['guest_id'] as int?,
    depositAmount: (map['deposit_amount'] as num?)?.toDouble() ?? 0,
    depositPaid: ((map['deposit_paid'] as num?)?.toInt() ?? 0) == 1,
    idVerified: ((map['id_verified'] as num?)?.toInt() ?? 0) == 1,
    petType: map['pet_type'] as String?,
    petCount: (map['pet_count'] as num?)?.toInt() ?? 0,
    petFee: (map['pet_fee'] as num?)?.toDouble() ?? 0,
    discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0,
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
    'guest_id': guestId,
    'deposit_amount': depositAmount,
    'deposit_paid': depositPaid ? 1 : 0,
    'id_verified': idVerified ? 1 : 0,
    'pet_type': petType,
    'pet_count': petCount,
    'pet_fee': petFee,
    'discount_amount': discountAmount,
  };

  Stay copyWith({
    int? id,
    String? guestName,
    String? phone,
    int? roomId,
    String? checkInDate,
    String? checkOutDate,
    int? guests,
    int? extraBed,
    double? totalAmount,
    int? status,
    String? note,
    String? createdAt,
    int? guestId,
    double? depositAmount,
    bool? depositPaid,
    bool? idVerified,
    String? petType,
    int? petCount,
    double? petFee,
    double? discountAmount,
  }) => Stay(
    id: id ?? this.id,
    guestName: guestName ?? this.guestName,
    phone: phone ?? this.phone,
    roomId: roomId ?? this.roomId,
    checkInDate: checkInDate ?? this.checkInDate,
    checkOutDate: checkOutDate ?? this.checkOutDate,
    guests: guests ?? this.guests,
    extraBed: extraBed ?? this.extraBed,
    totalAmount: totalAmount ?? this.totalAmount,
    status: status ?? this.status,
    note: note ?? this.note,
    createdAt: createdAt ?? this.createdAt,
    guestId: guestId ?? this.guestId,
    depositAmount: depositAmount ?? this.depositAmount,
    depositPaid: depositPaid ?? this.depositPaid,
    idVerified: idVerified ?? this.idVerified,
    petType: petType ?? this.petType,
    petCount: petCount ?? this.petCount,
    petFee: petFee ?? this.petFee,
    discountAmount: discountAmount ?? this.discountAmount,
  );
}

/// รายการเข้าพักที่พ่วงชื่อห้องกับโซนมาด้วย
/// ใช้กับหน้าจอที่ต้องแสดงว่าแขกอยู่ห้องไหน โดยไม่ต้องยิงคิวรีถามชื่อห้องซ้ำทีละรายการ
class StayWithRoom {
  final Stay stay;
  final String roomName;
  final String zone;
  final String? customerType;
  final bool isRegular;
  final int? feedbackRating;

  const StayWithRoom({
    required this.stay,
    required this.roomName,
    required this.zone,
    this.customerType,
    this.isRegular = false,
    this.feedbackRating,
  });

  factory StayWithRoom.fromMap(Map<String, Object?> map) => StayWithRoom(
    stay: Stay.fromMap(map),
    roomName: map['room_name'] as String,
    zone: map['zone'] as String,
    customerType: map['customer_type'] as String?,
    isRegular: ((map['is_regular'] as num?)?.toInt() ?? 0) == 1,
    feedbackRating: (map['feedback_rating'] as num?)?.toInt(),
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
  final int petCount;
  final double petFeePerNight;
  final double discountAmount;
  final double depositAmount;
  final bool depositPaid;

  const PriceBreakdown({
    required this.nights,
    required this.roomRate,
    required this.extraGuests,
    required this.extraGuestFee,
    required this.extraBed,
    required this.extraBedFee,
    this.petCount = 0,
    this.petFeePerNight = 0,
    this.discountAmount = 0,
    this.depositAmount = 0,
    this.depositPaid = false,
  });

  double get roomTotal => roomRate * nights;
  double get extraGuestTotal => extraGuestFee * extraGuests * nights;
  double get extraBedTotal => extraBed ? extraBedFee : 0;
  double get petTotal => petCount > 0 ? petFeePerNight * nights : 0;
  double get grossTotal =>
      roomTotal + extraGuestTotal + extraBedTotal + petTotal;
  double get total => (grossTotal - discountAmount).clamp(0, double.infinity);
  double get paidDeposit => depositPaid ? depositAmount : 0;
  double get balanceDue => (total - paidDeposit).clamp(0, double.infinity);

  /// คิดยอดจากห้อง จำนวนคน ช่วงวันที่ และการขอเตียงเสริม
  factory PriceBreakdown.calculate({
    required Room room,
    required int guests,
    required String checkInDate,
    required String checkOutDate,
    required bool extraBed,
    int petCount = 0,
    double discountAmount = 0,
    double depositAmount = 0,
    bool depositPaid = false,
  }) {
    // ต้องครอบด้วยค่าต่ำสุด 0 เผื่อผู้ใช้กรอกจำนวนคนน้อยกว่าที่ราคาห้องครอบคลุม
    // ถ้าไม่ครอบ ค่าคนเพิ่มจะติดลบและไปหักยอดรวมจนเงินผิด
    final int extraGuests = (guests - room.baseGuests) > 0
        ? guests - room.baseGuests
        : 0;

    return PriceBreakdown(
      nights: nightsBetween(checkInDate, checkOutDate),
      roomRate: room.price,
      extraGuests: extraGuests,
      extraGuestFee: room.extraGuestFee,
      extraBed: extraBed,
      extraBedFee: ResortConfig.extraBedFee,
      petCount: petCount,
      petFeePerNight: ResortConfig.petFeePerNight,
      discountAmount: discountAmount,
      depositAmount: depositAmount,
      depositPaid: depositPaid,
    );
  }
}
