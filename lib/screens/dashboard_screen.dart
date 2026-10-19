// Dashboard ตามช่วงวันที่ พร้อมการ์ดสรุปและกราฟที่วาดด้วย Flutter โดยไม่ใช้ package เพิ่ม
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../db/database_helper.dart';
import '../models/analytics.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _range = 'today';
  late DateTime _start = dateOnly(DateTime.now()),
      _end = dateOnly(DateTime.now());
  void _choose(String value) {
    final now = dateOnly(DateTime.now());
    setState(() {
      _range = value;
      if (value == 'today') {
        _start = now;
        _end = now;
      } else if (value == '7days') {
        _start = now.subtract(const Duration(days: 6));
        _end = now;
      } else if (value == 'month') {
        _start = DateTime(now.year, now.month, 1);
        _end = now;
      }
    });
  }

  Future<void> _custom() async {
    final value = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1095)),
      initialDateRange: DateTimeRange(start: _start, end: _end),
    );
    if (value != null) {
      setState(() {
        _range = 'custom';
        _start = value.start;
        _end = value.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: <Widget>[
              _chip('วันนี้', 'today'),
              _chip('7 วันล่าสุด', '7days'),
              _chip('เดือนนี้', 'month'),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                    _range == 'custom'
                        ? '${formatThaiDate(_start)} – ${formatThaiDate(_end)}'
                        : 'กำหนดเอง',
                  ),
                  selected: _range == 'custom',
                  onSelected: (_) => _custom(),
                ),
              ),
            ],
          ),
        ),
      ),
      Expanded(
        child: ValueListenableBuilder<int>(
          valueListenable: dbRevision,
          builder: (context, revision, child) =>
              FutureBuilder<DashboardRangeData>(
                future: DatabaseHelper.instance.getDashboardByDateRange(
                  toIsoDate(_start),
                  toIsoDate(_end),
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            'โหลด Dashboard ไม่สำเร็จ\n${snapshot.error}',
                            textAlign: TextAlign.center,
                          ),
                          TextButton(
                            onPressed: () => setState(() {}),
                            child: const Text('ลองใหม่'),
                          ),
                        ],
                      ),
                    );
                  }
                  final data = snapshot.data!;
                  return _body(data);
                },
              ),
        ),
      ),
    ],
  );
  Widget _chip(String label, String value) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: _range == value,
      onSelected: (_) => _choose(value),
    ),
  );
  Widget _body(DashboardRangeData d) => ListView(
    padding: const EdgeInsets.fromLTRB(14, 8, 14, 100),
    children: <Widget>[
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'อัตราการเข้าพัก',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              '${(d.occupancyRate * 100).toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryDark,
              ),
            ),
            LinearProgressIndicator(
              value: d.occupancyRate.clamp(0, 1),
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 6),
            Text(
              '${d.occupiedRoomNights} room nights จาก ${d.totalRooms * d.dayCount}',
              style: const TextStyle(color: AppColors.muted),
            ),
            Text(
              'วันสุดท้ายของช่วง: ว่าง ${d.vacantRoomsAtEnd} · ไม่ว่าง ${d.occupiedRoomsAtEnd} ห้อง',
              style: const TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        childAspectRatio: 1.55,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        children: <Widget>[
          StatCard(
            icon: Icons.event_note,
            label: 'Booking',
            value: '${d.bookingCount}',
            accent: AppColors.primary,
          ),
          StatCard(
            icon: Icons.people_outline,
            label: 'จำนวนแขก',
            value: '${d.guestCount}',
            accent: AppColors.primary,
          ),
          StatCard(
            icon: Icons.login,
            label: 'เช็กอิน',
            value: '${d.checkInCount}',
            accent: AppColors.success,
          ),
          StatCard(
            icon: Icons.logout,
            label: 'เช็กเอาต์',
            value: '${d.checkOutCount}',
            accent: AppColors.success,
          ),
          StatCard(
            icon: Icons.payments_outlined,
            label: 'รายได้สุทธิ',
            value: formatBaht(d.netRevenue),
            accent: AppColors.primaryDark,
          ),
          StatCard(
            icon: Icons.discount_outlined,
            label: 'ส่วนลด',
            value: formatBaht(d.totalDiscount),
            accent: AppColors.warning,
          ),
          StatCard(
            icon: Icons.savings_outlined,
            label: 'มัดจำรับแล้ว',
            value: formatBaht(d.depositReceived),
            accent: AppColors.success,
          ),
          StatCard(
            icon: Icons.pets,
            label: 'Booking มีสัตว์',
            value: '${d.petBookings}',
            accent: AppColors.occupied,
          ),
        ],
      ),
      const SizedBox(height: 12),
      _barCard(
        'รายได้สุทธิรายวัน',
        d.revenueChart.map((e) => e.amount).toList(),
        d.revenueChart.map((e) => e.date.substring(5)).toList(),
        money: true,
      ),
      const SizedBox(height: 12),
      _barCard(
        'อัตราการเข้าพักรายวัน',
        d.occupancyChart.map((e) => e.rate * 100).toList(),
        d.occupancyChart.map((e) => e.date.substring(5)).toList(),
      ),
      const SizedBox(height: 12),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: _donutCard(
              'สถานะ Booking',
              <double>[
                d.bookingStatuses.booked.toDouble(),
                d.bookingStatuses.checkedIn.toDouble(),
                d.bookingStatuses.checkedOut.toDouble(),
              ],
              const <String>['รอเช็กอิน', 'กำลังพัก', 'เช็กเอาต์'],
              const <Color>[
                AppColors.warning,
                AppColors.primary,
                AppColors.success,
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _donutCard(
              'สถานะมัดจำ',
              <double>[
                d.depositStatuses.none.toDouble(),
                d.depositStatuses.paid.toDouble(),
                d.depositStatuses.unpaid.toDouble(),
              ],
              const <String>['ไม่มี', 'ชำระแล้ว', 'ค้างชำระ'],
              const <Color>[
                AppColors.muted,
                AppColors.success,
                AppColors.warning,
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      AppCard(
        child: Wrap(
          spacing: 16,
          runSpacing: 8,
          children: <Widget>[
            Text('ก่อนส่วนลด ${formatBaht(d.grossRevenue)}'),
            Text('มัดจำค้างรับ ${formatBaht(d.depositPending)}'),
            Text(
              'Feedback เฉลี่ย ${d.averageFeedback == 0 ? '-' : d.averageFeedback.toStringAsFixed(1)} / 5',
            ),
          ],
        ),
      ),
    ],
  );
  Widget _barCard(
    String title,
    List<double> raw,
    List<String> labels, {
    bool money = false,
  }) {
    final int step = math.max(1, (raw.length / 14).ceil());
    final List<double> values = <double>[];
    final List<String> names = <String>[];
    for (int i = 0; i < raw.length; i += step) {
      final Iterable<double> chunk = raw.skip(i).take(step);
      final double sum = chunk.fold<double>(0, (double a, double b) => a + b);
      values.add(money ? sum : sum / chunk.length);
      names.add(labels[i]);
    }
    final double maxValue = values.isEmpty ? 0 : values.reduce(math.max);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          if (maxValue == 0)
            const SizedBox(
              height: 120,
              child: Center(
                child: Text(
                  'ยังไม่มีข้อมูล',
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
            )
          else
            SizedBox(
              height: 150,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List<Widget>.generate(values.length, (int i) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          Text(
                            money
                                ? formatMoney(values[i])
                                : '${values[i].round()}%',
                            style: const TextStyle(fontSize: 8),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            height: math.max(3.0, 105 * values[i] / maxValue),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            names[i],
                            style: const TextStyle(fontSize: 8),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _donutCard(
    String title,
    List<double> values,
    List<String> labels,
    List<Color> colors,
  ) {
    final double total = values.fold(0, (a, b) => a + b);
    return AppCard(
      child: Column(
        children: <Widget>[
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 100,
            height: 100,
            child: CustomPaint(
              painter: _DonutPainter(values, colors),
              child: Center(
                child: Text(
                  '${total.round()}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...List<Widget>.generate(
            labels.length,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                children: <Widget>[
                  Container(width: 8, height: 8, color: colors[i]),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(labels[i], style: const TextStyle(fontSize: 9)),
                  ),
                  Text(
                    '${values[i].round()}',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.values, this.colors);
  final List<double> values;
  final List<Color> colors;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final total = values.fold<double>(0, (a, b) => a + b);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.butt;
    if (total == 0) {
      paint.color = AppColors.line;
      canvas.drawArc(rect.deflate(8), 0, math.pi * 2, false, paint);
      return;
    }
    double start = -math.pi / 2;
    for (int i = 0; i < values.length; i++) {
      final sweep = math.pi * 2 * values[i] / total;
      paint.color = colors[i];
      canvas.drawArc(rect.deflate(8), start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => old.values != values;
}
