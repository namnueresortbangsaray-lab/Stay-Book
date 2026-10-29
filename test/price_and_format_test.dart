// ชุดทดสอบสูตรคิดเงินและฟังก์ชันแปลงข้อมูล
//
// เลือกทดสอบสองส่วนนี้เพราะเป็นตรรกะที่ผิดแล้วเสียหายเป็นตัวเงิน และตรวจด้วยตาได้ยาก
// ส่วนที่ต้องต่อกับฐานข้อมูลจริงไม่ได้ทดสอบที่นี่ เพราะ sqflite ต้องรันบนอุปกรณ์
import 'package:flutter_test/flutter_test.dart';
import 'package:stay_book/models/room.dart';
import 'package:stay_book/models/stay.dart';
import 'package:stay_book/utils/formatters.dart';

void main() {
  const Room doubleRoom = Room(
    id: 3,
    name: '3',
    zone: 'อาคารหลัก',
    type: 'เตียงคู่',
    price: 500,
    baseGuests: 2,
    maxGuests: 3,
    extraGuestFee: 100,
  );

  group('สูตรคิดเงิน', () {
    test('ห้อง 3 พัก 3 ท่าน 2 คืน ขอเตียงเสริม ต้องได้ 1,400', () {
      final PriceBreakdown result = PriceBreakdown.calculate(
        room: doubleRoom,
        guests: 3,
        checkInDate: '2026-08-18',
        checkOutDate: '2026-08-20',
        extraBed: true,
      );

      expect(result.nights, 2);
      expect(result.roomTotal, 1000);
      expect(result.extraGuestTotal, 200);
      // ค่าเตียงเสริมคิดครั้งเดียว ไม่คูณสองคืน ถ้าคูณจะได้ 400 แล้วยอดรวมจะเป็น 1,600
      expect(result.extraBedTotal, 200);
      expect(result.total, 1400);
    });

    test('กรอกจำนวนคนน้อยกว่าคนพื้นฐาน ต้องไม่คิดค่าคนเพิ่มติดลบ', () {
      final PriceBreakdown result = PriceBreakdown.calculate(
        room: doubleRoom,
        guests: 1,
        checkInDate: '2026-08-18',
        checkOutDate: '2026-08-19',
        extraBed: false,
      );

      expect(result.extraGuests, 0);
      expect(result.total, 500);
    });
  });

  group('ฟังก์ชันแปลงข้อมูล', () {
    test('จำนวนคืนคำนวณจากผลต่างของวันที่', () {
      expect(nightsBetween('2026-08-18', '2026-08-21'), 3);
    });

    test('ใส่ลูกน้ำหลักพันและตัดทศนิยมที่ลงตัว', () {
      expect(formatMoney(1400), '1,400');
      expect(formatMoney(1234567), '1,234,567');
      expect(formatMoney(1400.5), '1,400.50');
    });

    test('แปลงวันที่เป็นพุทธศักราชแบบไทย', () {
      expect(formatThaiDate(DateTime(2026, 8, 18)), '18 ส.ค. 2569');
    });

    test('แปลง DateTime เป็นข้อความ yyyy-MM-dd แบบเติมศูนย์หน้า', () {
      expect(toIsoDate(DateTime(2026, 1, 5)), '2026-01-05');
    });
  });
}
