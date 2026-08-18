// ผลสรุปตัวเลขทั้งหมดของหน้าภาพรวม รวมไว้ในอ็อบเจกต์เดียว
// เพื่อให้หน้า Dashboard เรียกฐานข้อมูลครั้งเดียวแล้วได้ตัวเลขครบ ไม่ต้องยิงหลายคิวรีจากหน้าจอ
import 'stay.dart';

class DashboardData {
  /// จำนวนห้องทั้งหมดในระบบ ใช้เป็นตัวหารของอัตราการเข้าพัก
  final int totalRooms;

  /// ห้องที่มีแขกอยู่ตอนนี้ (rooms.status = 1)
  final int occupiedRooms;

  /// จำนวนแขกที่มีกำหนดเข้าวันนี้และเช็คอินเรียบร้อยแล้ว
  final int checkedInToday;

  /// จำนวนแขกที่จองไว้วันนี้แต่ยังไม่มาเช็คอิน คือคิวงานที่เหลือของวัน
  final int pendingToday;

  /// จำนวนห้องที่ครบกำหนดคืนห้องวันนี้ ใช้วางแผนแม่บ้าน
  final int dueOutToday;

  /// ยอดเงินของรายการที่เริ่มเข้าพักวันนี้และเช็คอินแล้ว
  final double revenueToday;

  /// ยอดเงินสะสมของเดือนปัจจุบัน นับจากวันเช็คอินของแต่ละรายการ
  final double revenueMonth;

  /// รายชื่อแขกที่ต้องมาถึงวันนี้แต่ยังไม่เช็คอิน แสดงเป็นรายการให้กดเช็คอินได้เลย
  final List<StayWithRoom> pendingArrivals;

  const DashboardData({
    required this.totalRooms,
    required this.occupiedRooms,
    required this.checkedInToday,
    required this.pendingToday,
    required this.dueOutToday,
    required this.revenueToday,
    required this.revenueMonth,
    required this.pendingArrivals,
  });

  int get vacantRooms => totalRooms - occupiedRooms;

  /// สัดส่วนการเข้าพัก 0.0 ถึง 1.0 ส่งให้ LinearProgressIndicator ใช้ได้ตรง ๆ
  /// ต้องกันหารด้วยศูนย์เผื่อกรณีผู้ใช้ลบห้องออกจนหมด
  double get occupancyRate => totalRooms == 0 ? 0 : occupiedRooms / totalRooms;

  /// เปอร์เซ็นต์แบบปัดเป็นจำนวนเต็มสำหรับแสดงตัวใหญ่บนการ์ด
  int get occupancyPercent => (occupancyRate * 100).round();
}
