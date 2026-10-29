// หน้าภาพรวมของวันนี้ ตอบคำถามเชิงจัดการ เช่น ห้องเต็มกี่เปอร์เซ็นต์
// เหลือใครที่ยังไม่มาเช็คอิน และวันนี้มีรายรับเท่าไร
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../db/database_helper.dart';
import '../models/dashboard_data.dart';
import '../models/stay.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: dbRevision,
      builder: (BuildContext context, int revision, Widget? child) {
        return FutureBuilder<DashboardData>(
          future: DatabaseHelper.instance.getDashboard(),
          builder: (BuildContext context, AsyncSnapshot<DashboardData> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final DashboardData? data = snapshot.data;
            if (data == null) {
              return const EmptyState(
                icon: Icons.insights_outlined,
                title: 'ยังไม่มีข้อมูลให้สรุป',
              );
            }
            return _DashboardBody(data: data);
          },
        );
      },
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.data});

  final DashboardData data;

  /// กดเช็คอินจากหน้านี้ได้เลย เพื่อไม่ต้องเปลี่ยนไปหน้าตารางเข้าพักซ้ำอีกรอบ
  Future<void> _checkIn(BuildContext context, StayWithRoom item) async {
    await DatabaseHelper.instance.checkIn(item.stay.id!);
    if (!context.mounted) return;
    showAppSnackBar(context, 'เช็คอิน ${item.stay.guestName} เข้าห้อง ${item.roomName} แล้ว');
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 96),
      children: <Widget>[
        _OccupancyCard(data: data),
        const SectionTitle(title: 'สรุปของวันนี้'),
        // ตาราง 2x2 ของการ์ดตัวเลข ใช้ GridView แบบไม่เลื่อนเอง เพราะอยู่ใน ListView อยู่แล้ว
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.55,
          children: <Widget>[
            StatCard(
              icon: Icons.login,
              label: 'เช็คอินแล้ววันนี้',
              value: '${data.checkedInToday}',
            ),
            StatCard(
              icon: Icons.hourglass_bottom,
              label: 'ยังไม่เช็คอิน',
              value: '${data.pendingToday}',
              accent: AppColors.occupied,
            ),
            StatCard(
              icon: Icons.logout,
              label: 'ครบกำหนดออกวันนี้',
              value: '${data.dueOutToday}',
            ),
            StatCard(
              icon: Icons.payments_outlined,
              label: 'รายรับวันนี้',
              value: formatBaht(data.revenueToday),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _MonthRevenueBar(amount: data.revenueMonth),
        const SectionTitle(title: 'รอเช็คอินวันนี้'),
        if (data.pendingArrivals.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.vacantBg,
              borderRadius: BorderRadius.circular(AppRadius.large),
              border: Border.all(color: AppColors.vacantBorder, width: 0.5),
            ),
            child: const Row(
              children: <Widget>[
                Icon(Icons.check_circle_outline, color: AppColors.primaryDark),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'แขกที่จองไว้วันนี้เช็คอินครบแล้ว ไม่มีคิวค้าง',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          for (final StayWithRoom item in data.pendingArrivals)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PendingArrivalTile(
                item: item,
                onCheckIn: () => _checkIn(context, item),
              ),
            ),
      ],
    );
  }
}

/// การ์ดอัตราการเข้าพัก แสดงเปอร์เซ็นต์ตัวใหญ่พร้อมแถบความคืบหน้า
class _OccupancyCard extends StatelessWidget {
  const _OccupancyCard({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'อัตราการเข้าพักวันนี้',
            style: TextStyle(fontSize: 14, color: AppColors.muted),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text(
                '${data.occupancyPercent}',
                style: const TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                  height: 1,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                '%',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
              const Spacer(),
              Text(
                '${data.occupiedRooms} / ${data.totalRooms} ห้อง',
                style: const TextStyle(fontSize: 14, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: data.occupancyRate,
              minHeight: 10,
              backgroundColor: AppColors.vacantBg,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              _Dot(color: AppColors.primary, label: 'ว่าง ${data.vacantRooms} ห้อง'),
              const SizedBox(width: 16),
              _Dot(color: AppColors.occupied, label: 'ไม่ว่าง ${data.occupiedRooms} ห้อง'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.ink)),
      ],
    );
  }
}

/// แถบรายรับสะสมของเดือนปัจจุบัน
class _MonthRevenueBar extends StatelessWidget {
  const _MonthRevenueBar({required this.amount});

  final double amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.vacantBg,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.vacantBorder, width: 0.5),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.calendar_month_outlined, color: AppColors.primaryDark),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'รายรับสะสมเดือนนี้',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ),
          Text(
            formatBaht(amount),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

/// รายชื่อแขกที่จองไว้วันนี้แต่ยังไม่มาเช็คอิน พร้อมปุ่มเช็คอินในตัว
class _PendingArrivalTile extends StatelessWidget {
  const _PendingArrivalTile({required this.item, required this.onCheckIn});

  final StayWithRoom item;
  final VoidCallback onCheckIn;

  @override
  Widget build(BuildContext context) {
    final Stay stay = item.stay;

    return AppCard(
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(AppRadius.medium),
              border: Border.all(color: AppColors.line, width: 0.5),
            ),
            child: Text(
              item.roomName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
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
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  '${stay.guests} ท่าน · ${stay.nights} คืน · ${formatBaht(stay.totalAmount)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: onCheckIn,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: const Text('เช็คอิน'),
          ),
        ],
      ),
    );
  }
}
