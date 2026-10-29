// การ์ดหนึ่งใบของรายการเข้าพัก ใช้ในหน้าตารางเข้าพัก
// รับหน้าที่แค่แสดงผลกับส่งสัญญาณเมื่อผู้ใช้กดปุ่ม ส่วนการแตะฐานข้อมูลเป็นงานของหน้าจอ
import 'package:flutter/material.dart';

import '../models/stay.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'common_widgets.dart';

class StayCard extends StatelessWidget {
  const StayCard({
    super.key,
    required this.data,
    required this.onCheckIn,
    required this.onCheckOut,
  });

  final StayWithRoom data;
  final VoidCallback onCheckIn;
  final VoidCallback onCheckOut;

  @override
  Widget build(BuildContext context) {
    final Stay stay = data.stay;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _RoomBadge(roomName: data.roomName),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      stay.guestName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      (stay.phone == null || stay.phone!.isEmpty)
                          ? 'ไม่ได้ระบุเบอร์โทร'
                          : stay.phone!,
                      style: const TextStyle(fontSize: 13, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              StatusChip(status: stay.status),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            children: <Widget>[
              const Icon(Icons.calendar_today_outlined, size: 15, color: AppColors.muted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${formatIsoAsThaiDate(stay.checkInDate)} - '
                  '${formatIsoAsThaiDate(stay.checkOutDate)}',
                  style: const TextStyle(fontSize: 13, color: AppColors.ink),
                ),
              ),
              Text(
                '${stay.nights} คืน',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: <Widget>[
              // ห่อข้อมูลฝั่งซ้ายด้วย Expanded ให้ยอมหดตัวก่อน เพราะยอดเงินฝั่งขวา
              // เป็นข้อมูลที่ห้ามถูกตัดทิ้ง ต้องอ่านได้เต็มจำนวนเสมอ
              Expanded(
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.people_outline, size: 15, color: AppColors.muted),
                    const SizedBox(width: 6),
                    Text(
                      '${stay.guests} ท่าน',
                      style: const TextStyle(fontSize: 13, color: AppColors.ink),
                    ),
                    if (stay.hasExtraBed) ...<Widget>[
                      const SizedBox(width: 12),
                      const Icon(Icons.bed_outlined, size: 15, color: AppColors.muted),
                      const SizedBox(width: 4),
                      const Flexible(
                        child: Text(
                          'เตียงเสริม',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, color: AppColors.ink),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatBaht(stay.totalAmount),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          if (stay.note != null && stay.note!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: Text(
                'หมายเหตุ: ${stay.note}',
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
            ),
          ],
          // ปุ่มเปลี่ยนไปตามสถานะ เพราะแต่ละสถานะมีงานถัดไปได้อย่างเดียวเท่านั้น
          // การซ่อนปุ่มที่กดไม่ได้ ช่วยไม่ให้พนักงานกดผิดตอนรีบ
          if (stay.status == Stay.statusBooked) ...<Widget>[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onCheckIn,
                icon: const Icon(Icons.login, size: 18),
                label: const Text('เช็คอิน'),
              ),
            ),
          ] else if (stay.status == Stay.statusCheckedIn) ...<Widget>[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onCheckOut,
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('เช็คเอาท์'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// ป้ายเลขห้องทรงสี่เหลี่ยมด้านหน้าการ์ด ช่วยให้กวาดตาหาห้องที่ต้องการได้เร็ว
class _RoomBadge extends StatelessWidget {
  const _RoomBadge({required this.roomName});

  final String roomName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.vacantBg,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: AppColors.vacantBorder, width: 0.5),
      ),
      child: Text(
        roomName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: AppColors.primaryDark,
        ),
      ),
    );
  }
}
