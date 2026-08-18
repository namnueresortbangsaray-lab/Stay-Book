// การ์ดห้องหนึ่งใบในหน้าผังห้องพัก
// แยกออกมาเป็นไฟล์ของตัวเอง เพราะตรรกะการเลือกสีตามสถานะห้องมีรายละเอียดพอสมควร
// ถ้าเขียนปนอยู่ในหน้าจอจะทำให้ไฟล์หน้าจออ่านยาก
import 'package:flutter/material.dart';

import '../models/room.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class RoomTile extends StatelessWidget {
  const RoomTile({super.key, required this.data, required this.onTap});

  /// ข้อมูลห้องพร้อมแขกคนปัจจุบัน (ถ้ามี)
  final RoomWithStay data;

  /// ห้องว่างจะเปิดฟอร์มจอง ส่วนห้องไม่ว่างจะเปิดแผ่นข้อมูลแขกด้านล่าง
  /// หน้าจอเป็นคนตัดสินใจ การ์ดใบนี้แค่ส่งสัญญาณว่าถูกแตะ
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool occupied = data.isOccupied;
    final Color background = occupied ? AppColors.occupiedBg : AppColors.vacantBg;
    final Color border = occupied ? AppColors.occupiedBorder : AppColors.vacantBorder;
    final Color textColor = occupied ? AppColors.occupiedInk : AppColors.ink;
    final Color subTextColor = occupied ? AppColors.occupiedMuted : AppColors.muted;
    final Color dotColor = occupied ? AppColors.occupied : AppColors.primary;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(AppRadius.large),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.large),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.large),
            border: Border.all(color: border, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      data.room.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                  ),
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                occupied ? (data.guestName ?? '-') : 'ว่าง',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: subTextColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                occupied ? _remainingLabel(data.nightsLeft) : formatBaht(data.room.price),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: occupied ? AppColors.occupied : AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ข้อความบอกจำนวนคืนที่เหลือ
  ///
  /// เมื่อเหลือ 0 คืนแปลว่าวันนี้คือวันเช็คเอาท์ จึงเขียนเป็นคำสั่งงานว่า "ออกก่อน 12:00"
  /// ซึ่งบอกสิ่งที่พนักงานต้องทำได้ตรงกว่าการเขียนว่า "อีก 0 คืน"
  /// ค่าติดลบแปลว่าเลยกำหนดมาแล้วแต่ยังไม่ได้กดเช็คเอาท์ ต้องเตือนให้เห็นชัด
  static String _remainingLabel(int? nightsLeft) {
    if (nightsLeft == null) return '-';
    if (nightsLeft > 0) return 'อีก $nightsLeft คืน';
    if (nightsLeft == 0) return 'ออกก่อน 12:00';
    return 'เลยกำหนด ${-nightsLeft} วัน';
  }
}
