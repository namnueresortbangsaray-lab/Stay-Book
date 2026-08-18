// วิดเจ็ตชิ้นเล็ก ๆ ที่ถูกใช้ซ้ำในหลายหน้าจอ
// รวมไว้ที่เดียวเพื่อให้หน้าตาของหัวข้อ ป้ายสถานะ และการ์ดตัวเลขเหมือนกันทั้งแอป
import 'package:flutter/material.dart';

import '../models/stay.dart';
import '../theme/app_theme.dart';

/// หัวข้อของแต่ละส่วนในหน้าจอ พร้อมข้อความเสริมด้านขวา เช่น "ว่าง 7 / 10"
class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
        ],
      ),
    );
  }
}

/// ป้ายสถานะของรายการเข้าพัก
///
/// จับคู่สีให้ตรงกับหน้าผังห้องโดยตั้งใจ คือสถานะ "เช็คอินแล้ว" ใช้โทนส้มเหมือน
/// การ์ดห้องไม่ว่าง ส่วน "เช็คเอาท์แล้ว" ใช้โทนเขียวเหมือนห้องว่าง
/// ผู้ใช้จึงเดาความหมายของสีได้โดยไม่ต้องอ่านข้อความ
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final int status;

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color background;
    late final Color foreground;
    late final Color border;

    switch (status) {
      case Stay.statusCheckedIn:
        label = 'เช็คอินแล้ว';
        background = AppColors.occupiedBg;
        foreground = AppColors.occupied;
        border = AppColors.occupiedBorder;
      case Stay.statusCheckedOut:
        label = 'เช็คเอาท์แล้ว';
        background = AppColors.vacantBg;
        foreground = AppColors.primaryDark;
        border = AppColors.vacantBorder;
      default:
        label = 'รอเช็คอิน';
        background = AppColors.surface;
        foreground = AppColors.muted;
        border = AppColors.line;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

/// การ์ดแสดงตัวเลขหนึ่งค่าในหน้าภาพรวม
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.accent = AppColors.primaryDark,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.line, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 13, color: AppColors.muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

/// หน้าจอเปล่าเมื่อไม่มีข้อมูลให้แสดง บอกผู้ใช้ว่าไม่ใช่แอปค้าง แต่ยังไม่มีข้อมูลจริง ๆ
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.hint,
  });

  final IconData icon;
  final String title;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 56, color: AppColors.vacantBorder),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            if (hint != null) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                hint!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// กล่องพื้นขาวขอบบางที่ใช้เป็นฐานของการ์ดเกือบทุกใบในแอป
/// ใช้ขอบบาง 0.5 px แทนเงา เพราะเงาสีเทาบนพื้นหลังเขียวอ่อนจะทำให้ภาพรวมดูขุ่น
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.line, width: 0.5),
      ),
      child: child,
    );
  }
}

/// แสดงข้อความแจ้งผลการทำงาน ใช้แทนการเรียก ScaffoldMessenger ซ้ำ ๆ ทุกหน้า
/// [isError] ทำให้แถบเป็นสีส้มแดง ใช้กับกรณีบันทึกไม่สำเร็จ เช่น จองวันทับซ้อน
void showAppSnackBar(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.occupied : AppColors.ink,
        duration: const Duration(seconds: 3),
      ),
    );
}
