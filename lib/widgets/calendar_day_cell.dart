// ช่องวันที่ของปฏิทิน ออกแบบให้ไม่ overflow แม้พื้นที่และฟอนต์มีขนาดเล็ก
import 'package:flutter/material.dart';

import '../models/stay.dart';
import '../theme/app_theme.dart';

class CalendarDayCell extends StatelessWidget {
  const CalendarDayCell({
    super.key,
    required this.day,
    required this.bookingCount,
    required this.statuses,
    required this.selected,
    required this.today,
    required this.onTap,
  });

  final int day;
  final int bookingCount;
  final Set<int> statuses;
  final bool selected;
  final bool today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryLight : AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : today
                  ? AppColors.warning
                  : AppColors.line,
              width: selected || today ? 1.4 : 0.5,
            ),
          ),
          // วางเลขวันและสถานะคนละตำแหน่ง จึงไม่เกิด RenderFlex แนวตั้ง
          child: Stack(
            children: <Widget>[
              Positioned(
                top: 4,
                left: 2,
                right: 2,
                child: Text(
                  '$day',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: TextStyle(
                    fontWeight: today || selected
                        ? FontWeight.w900
                        : FontWeight.w600,
                    fontSize: 12,
                    height: 1,
                  ),
                ),
              ),
              if (bookingCount > 0)
                Positioned(
                  left: 2,
                  right: 2,
                  bottom: 4,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ...statuses
                            .take(3)
                            .map(
                              (int status) => Padding(
                                padding: const EdgeInsets.only(right: 2),
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: statusColor(status),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                        Container(
                          constraints: const BoxConstraints(minWidth: 14),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 3,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceBlue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$bookingCount',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 8,
                              height: 1,
                              fontWeight: FontWeight.w700,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static Color statusColor(int status) {
    if (status == Stay.statusBooked) return AppColors.warning;
    if (status == Stay.statusCheckedIn) return AppColors.primary;
    return AppColors.success;
  }
}
