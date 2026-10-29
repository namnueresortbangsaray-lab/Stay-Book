// ฟังก์ชันแปลงข้อมูลให้อ่านง่ายสำหรับผู้ใช้ ทั้งวันที่แบบไทยและจำนวนเงิน
//
// เขียนเองทั้งหมดแทนการใช้แพ็กเกจ intl เพราะโปรเจกต์นี้ตั้งใจใช้แพ็กเกจน้อยที่สุด
// จะได้ไม่เจอปัญหาเวอร์ชันชนกันเวลานำไปติดตั้งบนเครื่องอื่น

/// ชื่อเดือนแบบย่อ ใช้กับวันที่ที่ต้องแสดงในพื้นที่แคบ เช่น การ์ดรายการเข้าพัก
const List<String> _thaiMonthsShort = <String>[
  'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
  'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.',
];

/// ชื่อเดือนแบบเต็ม ใช้กับหัวข้อที่มีพื้นที่พอ เช่น แถบเลือกวันของหน้าตารางเข้าพัก
const List<String> _thaiMonthsFull = <String>[
  'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
  'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม',
];

/// เรียงตาม DateTime.weekday ซึ่งเริ่มที่ 1 = วันจันทร์
const List<String> _thaiWeekdays = <String>[
  'จันทร์', 'อังคาร', 'พุธ', 'พฤหัสบดี', 'ศุกร์', 'เสาร์', 'อาทิตย์',
];

/// ตัดเวลาทิ้งเหลือเฉพาะวัน ใช้ก่อนนำวันที่ไปเปรียบเทียบกันเสมอ
/// เพราะ DateTime.now() มีชั่วโมงนาทีติดมาด้วย ถ้าไม่ตัดจะเทียบว่า "วันเดียวกัน" ไม่ได้
DateTime dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

/// แปลง DateTime เป็นข้อความรูปแบบ yyyy-MM-dd ซึ่งเป็นรูปแบบเดียวที่เก็บลงฐานข้อมูล
/// รูปแบบนี้เรียงลำดับและเปรียบเทียบด้วยตัวดำเนินการข้อความได้ตรงกับลำดับเวลาจริง
String toIsoDate(DateTime value) {
  final String month = value.month.toString().padLeft(2, '0');
  final String day = value.day.toString().padLeft(2, '0');
  return '${value.year.toString().padLeft(4, '0')}-$month-$day';
}

/// แปลงข้อความ yyyy-MM-dd จากฐานข้อมูลกลับเป็น DateTime
DateTime parseIsoDate(String value) {
  final List<String> parts = value.split('-');
  return DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}

/// วันที่ของวันนี้ในรูปแบบที่ใช้เก็บและเทียบกับฐานข้อมูล
String todayIso() => toIsoDate(DateTime.now());

/// วันที่แบบไทยย่อ เช่น 18 ส.ค. 2569 (บวก 543 เพื่อแปลงเป็นพุทธศักราช)
String formatThaiDate(DateTime value) =>
    '${value.day} ${_thaiMonthsShort[value.month - 1]} ${value.year + 543}';

/// วันที่แบบไทยเต็ม เช่น วันอังคารที่ 18 สิงหาคม 2569
String formatThaiDateFull(DateTime value) =>
    'วัน${_thaiWeekdays[value.weekday - 1]}ที่ ${value.day} '
    '${_thaiMonthsFull[value.month - 1]} ${value.year + 543}';

/// รับข้อความ yyyy-MM-dd จากฐานข้อมูลแล้วคืนวันที่แบบไทยย่อ
String formatIsoAsThaiDate(String isoDate) => formatThaiDate(parseIsoDate(isoDate));

/// ป้ายกำกับวันแบบเป็นกันเอง ถ้าเป็นวันนี้ พรุ่งนี้ หรือเมื่อวานจะบอกเป็นคำ
/// ผู้ใช้งานหน้าเคาน์เตอร์อ่าน "วันนี้" ได้เร็วกว่าอ่านวันที่เต็ม
String relativeDayLabel(DateTime value) {
  final int diff = dateOnly(value).difference(dateOnly(DateTime.now())).inDays;
  if (diff == 0) return 'วันนี้';
  if (diff == 1) return 'พรุ่งนี้';
  if (diff == -1) return 'เมื่อวาน';
  return formatThaiDate(value);
}

/// จำนวนคืนระหว่างวันเช็คอินกับวันเช็คเอาท์ รับเป็นข้อความ yyyy-MM-dd
/// ระบบไม่เก็บจำนวนคืนไว้ในฐานข้อมูล แต่คำนวณสด ๆ ทุกครั้งเพื่อไม่ให้ข้อมูลขัดแย้งกันเอง
int nightsBetween(String checkInIso, String checkOutIso) {
  final int nights = parseIsoDate(checkOutIso)
      .difference(parseIsoDate(checkInIso))
      .inDays;
  return nights < 1 ? 1 : nights; // กันกรณีข้อมูลผิดปกติ อย่างน้อยต้องคิดหนึ่งคืน
}

/// ใส่ลูกน้ำคั่นหลักพัน เช่น 1400 -> 1,400
String _groupThousands(int value) {
  final String digits = value.toString();
  final StringBuffer buffer = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    // นับตำแหน่งจากขวามาซ้าย ครบทุก 3 หลักที่ยังไม่ถึงตัวแรกให้ใส่ลูกน้ำ
    final int fromRight = digits.length - i;
    buffer.write(digits[i]);
    if (fromRight > 1 && (fromRight - 1) % 3 == 0) buffer.write(',');
  }
  return buffer.toString();
}

/// จำนวนเงินแบบอ่านง่าย ตัดทศนิยมทิ้งถ้าลงตัว เช่น 1400 -> 1,400 และ 1400.5 -> 1,400.50
String formatMoney(num value) {
  final bool isNegative = value < 0;
  final double absolute = value.abs().toDouble();
  int whole = absolute.floor();
  int cents = ((absolute - whole) * 100).round();
  if (cents == 100) {
    // ปัดเศษแล้วเต็มร้อยพอดี ต้องทดขึ้นหลักบาท ไม่งั้นจะได้ข้อความแบบ 99.100
    whole += 1;
    cents = 0;
  }
  final String text = cents == 0
      ? _groupThousands(whole)
      : '${_groupThousands(whole)}.${cents.toString().padLeft(2, '0')}';
  return isNegative ? '-$text' : text;
}

/// จำนวนเงินพร้อมสัญลักษณ์บาท ใช้ในที่ที่ต้องการความชัดเจนว่าเป็นเงิน
String formatBaht(num value) => '฿${formatMoney(value)}';
