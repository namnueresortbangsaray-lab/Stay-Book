// การ์ด Booking แสดงสถานะ ราคา มัดจำ การยืนยัน และปุ่มงานตามขั้นตอน
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
    this.onEdit,
    this.onExtend,
    this.onFeedback,
    this.onDetails,
    this.onDelete,
  });
  final StayWithRoom data;
  final VoidCallback onCheckIn;
  final VoidCallback onCheckOut;
  final VoidCallback? onEdit, onExtend, onFeedback, onDetails, onDelete;
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
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.vacantBorder),
                ),
                child: Text(
                  data.roomName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
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
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      stay.phone?.isNotEmpty == true
                          ? stay.phone!
                          : 'ไม่ได้ระบุเบอร์โทร',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    if (data.customerType != null)
                      Text(
                        '${data.customerType}${data.isRegular ? ' · ลูกค้าประจำ' : ''}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryDark,
                        ),
                      ),
                  ],
                ),
              ),
              StatusChip(status: stay.status),
            ],
          ),
          const Divider(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: <Widget>[
              _info(
                Icons.calendar_today_outlined,
                '${formatIsoAsThaiDate(stay.checkInDate)} – ${formatIsoAsThaiDate(stay.checkOutDate)}',
              ),
              _info(Icons.nights_stay_outlined, '${stay.nights} คืน'),
              _info(Icons.people_outline, '${stay.guests} ท่าน'),
              if (stay.hasPet)
                _info(
                  Icons.pets_outlined,
                  '${stay.petType} ${stay.petCount} ตัว',
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: <Widget>[
                _money('ราคาก่อนส่วนลด', stay.grossAmount),
                if (stay.discountAmount > 0)
                  _money('ส่วนลด', -stay.discountAmount),
                _money('ยอดสุทธิ', stay.totalAmount, bold: true),
                _money(
                  stay.depositAmount == 0
                      ? 'ไม่มีมัดจำ'
                      : stay.depositPaid
                      ? 'มัดจำชำระแล้ว'
                      : 'มัดจำยังไม่ชำระ',
                  stay.depositAmount,
                ),
                _money('ยอดคงเหลือ', stay.balanceDue, bold: true),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: <Widget>[
              _chip(
                stay.idVerified ? 'ตรวจบัตรแล้ว' : 'ยังไม่ตรวจบัตร',
                stay.idVerified ? AppColors.success : AppColors.warning,
              ),
              if (stay.hasPet) _chip('สัตว์เลี้ยง', AppColors.primary),
            ],
          ),
          if (stay.note?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'หมายเหตุ: ${stay.note}',
                style: const TextStyle(color: AppColors.muted),
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              if (stay.status == Stay.statusBooked && onEdit != null)
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('แก้ไข'),
                ),
              if (stay.status == Stay.statusBooked)
                FilledButton.icon(
                  onPressed: onCheckIn,
                  icon: const Icon(Icons.login, size: 18),
                  label: const Text('เช็กอิน'),
                ),
              if (stay.status == Stay.statusCheckedIn && onExtend != null)
                OutlinedButton.icon(
                  onPressed: onExtend,
                  icon: const Icon(Icons.more_time, size: 18),
                  label: const Text('ต่อเวลา'),
                ),
              if (stay.status == Stay.statusCheckedIn)
                FilledButton.icon(
                  onPressed: onCheckOut,
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('เช็กเอาต์'),
                ),
              if (stay.status == Stay.statusCheckedOut && onFeedback != null)
                OutlinedButton.icon(
                  onPressed: onFeedback,
                  icon: const Icon(Icons.star_outline, size: 18),
                  label: const Text('Feedback'),
                ),
              if (onDetails != null)
                TextButton(
                  onPressed: onDetails,
                  child: const Text('รายละเอียด'),
                ),
              if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  tooltip: 'ลบ',
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.danger,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _info(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Icon(icon, size: 15, color: AppColors.muted),
      const SizedBox(width: 4),
      Text(text, style: const TextStyle(fontSize: 12)),
    ],
  );
  Widget _chip(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
    ),
  );
  Widget _money(String label, double value, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          formatBaht(value),
          style: TextStyle(
            fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
            color: bold ? AppColors.primaryDark : AppColors.ink,
          ),
        ),
      ],
    ),
  );
}
