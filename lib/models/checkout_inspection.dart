// ข้อมูลตรวจห้องก่อนเช็กเอาต์และแบบประเมินหลังการเข้าพัก

class CheckoutInspection {
  const CheckoutInspection({
    this.id,
    required this.stayId,
    required this.keyReturned,
    required this.roomClean,
    required this.equipmentComplete,
    required this.noDamage,
    required this.minibarChecked,
    this.inspectionNote,
    required this.inspectedAt,
  });

  final int? id;
  final int stayId;
  final bool keyReturned;
  final bool roomClean;
  final bool equipmentComplete;
  final bool noDamage;
  final bool minibarChecked;
  final String? inspectionNote;
  final String inspectedAt;

  factory CheckoutInspection.fromMap(Map<String, Object?> map) =>
      CheckoutInspection(
        id: map['id'] as int?,
        stayId: map['stay_id'] as int,
        keyReturned: map['key_returned'] == 1,
        roomClean: map['room_clean'] == 1,
        equipmentComplete: map['equipment_complete'] == 1,
        noDamage: map['no_damage'] == 1,
        minibarChecked: map['minibar_checked'] == 1,
        inspectionNote: map['inspection_note'] as String?,
        inspectedAt: map['inspected_at'] as String,
      );

  Map<String, Object?> toMap() => <String, Object?>{
    'stay_id': stayId,
    'key_returned': keyReturned ? 1 : 0,
    'room_clean': roomClean ? 1 : 0,
    'equipment_complete': equipmentComplete ? 1 : 0,
    'no_damage': noDamage ? 1 : 0,
    'minibar_checked': minibarChecked ? 1 : 0,
    'inspection_note': inspectionNote,
    'inspected_at': inspectedAt,
  };
}

class GuestFeedback {
  const GuestFeedback({
    this.id,
    required this.stayId,
    required this.cleanlinessRating,
    required this.serviceRating,
    required this.facilityRating,
    required this.overallRating,
    this.wouldReturn = true,
    this.comment,
    required this.createdAt,
  });

  final int? id;
  final int stayId;
  final int cleanlinessRating;
  final int serviceRating;
  final int facilityRating;
  final int overallRating;
  final bool wouldReturn;
  final String? comment;
  final String createdAt;

  factory GuestFeedback.fromMap(Map<String, Object?> map) => GuestFeedback(
    id: map['id'] as int?,
    stayId: map['stay_id'] as int,
    cleanlinessRating: map['cleanliness_rating'] as int,
    serviceRating: map['service_rating'] as int,
    facilityRating: map['facility_rating'] as int,
    overallRating: map['overall_rating'] as int,
    wouldReturn: map['would_return'] == 1,
    comment: map['comment'] as String?,
    createdAt: map['created_at'] as String,
  );

  Map<String, Object?> toMap() => <String, Object?>{
    'stay_id': stayId,
    'cleanliness_rating': cleanlinessRating,
    'service_rating': serviceRating,
    'facility_rating': facilityRating,
    'overall_rating': overallRating,
    'would_return': wouldReturn ? 1 : 0,
    'comment': comment,
    'created_at': createdAt,
  };
}
