// โครงสร้างข้อมูลลูกค้าและสรุปประวัติที่ใช้ในหน้าค้นหาและหน้ารายละเอียด

import 'stay.dart';

class Guest {
  const Guest({
    this.id,
    required this.name,
    required this.phone,
    required this.normalizedPhone,
    this.customerType = 'ลูกค้าทั่วไป',
    this.isRegular = false,
    this.customerNote,
    this.preferences,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String name;
  final String phone;
  final String normalizedPhone;
  final String customerType;
  final bool isRegular;
  final String? customerNote;
  final String? preferences;
  final String createdAt;
  final String updatedAt;

  factory Guest.fromMap(Map<String, Object?> map) => Guest(
    id: map['id'] as int?,
    name: map['name'] as String,
    phone: map['phone'] as String,
    normalizedPhone: map['normalized_phone'] as String,
    customerType: map['customer_type'] as String? ?? 'ลูกค้าทั่วไป',
    isRegular: ((map['is_regular'] as num?)?.toInt() ?? 0) == 1,
    customerNote: map['customer_note'] as String?,
    preferences: map['preferences'] as String?,
    createdAt: map['created_at'] as String,
    updatedAt: map['updated_at'] as String,
  );

  Map<String, Object?> toMap() => <String, Object?>{
    'name': name,
    'phone': phone,
    'normalized_phone': normalizedPhone,
    'customer_type': customerType,
    'is_regular': isRegular ? 1 : 0,
    'customer_note': customerNote,
    'preferences': preferences,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  Guest copyWith({
    String? name,
    String? phone,
    String? normalizedPhone,
    String? customerType,
    bool? isRegular,
    String? customerNote,
    String? preferences,
    String? updatedAt,
  }) => Guest(
    id: id,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    normalizedPhone: normalizedPhone ?? this.normalizedPhone,
    customerType: customerType ?? this.customerType,
    isRegular: isRegular ?? this.isRegular,
    customerNote: customerNote ?? this.customerNote,
    preferences: preferences ?? this.preferences,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

class GuestSummary {
  const GuestSummary({
    required this.guest,
    required this.completedStays,
    required this.totalNights,
    required this.lifetimeValue,
    required this.totalDiscount,
    this.lastStayDate,
    this.lastRoomName,
  });

  final Guest guest;
  final int completedStays;
  final int totalNights;
  final double lifetimeValue;
  final double totalDiscount;
  final String? lastStayDate;
  final String? lastRoomName;

  factory GuestSummary.fromMap(Map<String, Object?> map) => GuestSummary(
    guest: Guest.fromMap(map),
    completedStays: (map['completed_stays'] as num?)?.toInt() ?? 0,
    totalNights: (map['total_nights'] as num?)?.toInt() ?? 0,
    lifetimeValue: (map['lifetime_value'] as num?)?.toDouble() ?? 0,
    totalDiscount: (map['total_discount'] as num?)?.toDouble() ?? 0,
    lastStayDate: map['last_stay_date'] as String?,
    lastRoomName: map['last_room_name'] as String?,
  );
}

class GuestHistory {
  const GuestHistory({required this.summary, required this.stays});
  final GuestSummary summary;
  final List<StayWithRoom> stays;
}
