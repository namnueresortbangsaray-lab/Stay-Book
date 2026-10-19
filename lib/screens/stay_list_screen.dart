// รายการ Booking ทั้งหมด พร้อมค้นหา กรอง และทำงานตามสถานะ
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../db/database_helper.dart';
import '../models/checkout_inspection.dart';
import '../models/stay.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/calendar_day_cell.dart';
import '../widgets/common_widgets.dart';
import '../widgets/stay_card.dart';
import 'booking_form_screen.dart';
import 'feedback_form_screen.dart';
import 'stay_actions.dart';

class StayListScreen extends StatefulWidget {
  const StayListScreen({super.key});
  @override
  State<StayListScreen> createState() => _StayListScreenState();
}

class _StayListScreenState extends State<StayListScreen> {
  final TextEditingController _search = TextEditingController();
  int? _status;
  bool _calendarMode = false;
  DateTime _calendarMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedCalendarDay = dateOnly(DateTime.now());
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, String message) async {
    try {
      await action();
      if (mounted) showAppSnackBar(context, message);
    } catch (error) {
      if (mounted) {
        showAppSnackBar(
          context,
          error.toString().replaceFirst('Bad state: ', ''),
          isError: true,
        );
      }
    }
  }

  Future<void> _edit(StayWithRoom item) async {
    final bool? saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => BookingFormScreen(existing: item)),
    );
    if (saved == true && mounted) {
      showAppSnackBar(context, 'แก้ไข Booking แล้ว');
    }
  }

  Future<void> _checkIn(StayWithRoom item) => _run(
    () => DatabaseHelper.instance.checkIn(item.stay.id!),
    'เช็กอิน ${item.stay.guestName} แล้ว',
  );
  Future<void> _extend(StayWithRoom item) async {
    if (await showExtendStayDialog(context, item) && mounted) {
      showAppSnackBar(context, 'ต่อระยะเวลาพักแล้ว');
    }
  }

  Future<void> _checkout(StayWithRoom item) async {
    final CheckoutInspection? value = await showCheckoutInspectionDialog(
      context,
      item.stay.id!,
    );
    if (value == null) return;
    try {
      await DatabaseHelper.instance.checkOutWithInspection(value);
      if (!mounted) return;
      showAppSnackBar(context, 'เช็กเอาต์ห้อง ${item.roomName} แล้ว');
      final bool? feedback = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('บันทึก Feedback'),
          content: const Text('ต้องการเปิดแบบประเมินตอนนี้หรือไว้ภายหลัง?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('ไว้ภายหลัง'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('เปิดแบบประเมิน'),
            ),
          ],
        ),
      );
      if (feedback == true && mounted) await _feedback(item);
    } catch (error) {
      if (mounted) showAppSnackBar(context, error.toString(), isError: true);
    }
  }

  Future<void> _feedback(StayWithRoom item) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FeedbackFormScreen(stayId: item.stay.id!),
      ),
    );
    if (saved == true && mounted) {
      showAppSnackBar(context, 'บันทึก Feedback แล้ว');
    }
  }

  Future<void> _delete(StayWithRoom item) async {
    final bool? yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('ยืนยันการลบ Booking'),
        content: Text(
          'ลบรายการของ ${item.stay.guestName} ห้อง ${item.roomName}? ข้อมูลที่ลบกู้คืนไม่ได้',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
    if (yes == true) {
      await _run(
        () => DatabaseHelper.instance.deleteStay(item.stay.id!),
        'ลบ Booking แล้ว',
      );
    }
  }

  void _details(StayWithRoom item) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '${item.stay.guestName} · ห้อง ${item.roomName}',
              style: Theme.of(sheetContext).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text('โทร ${item.stay.phone ?? '-'}'),
            Text(
              '${formatIsoAsThaiDate(item.stay.checkInDate)} – ${formatIsoAsThaiDate(item.stay.checkOutDate)}',
            ),
            Text(
              'ยอดสุทธิ ${formatBaht(item.stay.totalAmount)} · คงเหลือ ${formatBaht(item.stay.balanceDue)}',
            ),
            if (item.stay.hasPet)
              Text(
                'สัตว์เลี้ยง ${item.stay.petType} ${item.stay.petCount} ตัว',
              ),
            if (item.stay.note != null) Text('หมายเหตุ ${item.stay.note}'),
            const SizedBox(height: 20),
          ],
        ),
      ),
    ),
  );

  void _shiftMonth(int amount) {
    setState(() {
      _calendarMonth = DateTime(
        _calendarMonth.year,
        _calendarMonth.month + amount,
      );
      _selectedCalendarDay = _calendarMonth;
    });
  }

  void _goToCurrentMonth() {
    final DateTime today = dateOnly(DateTime.now());
    setState(() {
      _calendarMonth = DateTime(today.year, today.month);
      _selectedCalendarDay = today;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
          child: Column(
            children: <Widget>[
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<bool>(
                  segments: const <ButtonSegment<bool>>[
                    ButtonSegment<bool>(
                      value: false,
                      icon: Icon(Icons.view_list_outlined),
                      label: Text('รายการ'),
                    ),
                    ButtonSegment<bool>(
                      value: true,
                      icon: Icon(Icons.calendar_month_outlined),
                      label: Text('ปฏิทิน'),
                    ),
                  ],
                  selected: <bool>{_calendarMode},
                  onSelectionChanged: (Set<bool> value) =>
                      setState(() => _calendarMode = value.first),
                ),
              ),
              const SizedBox(height: 12),
              if (_calendarMode)
                _calendarToolbar()
              else ...<Widget>[
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    labelText: 'ค้นหาชื่อ เบอร์ ห้อง โซน หรือหมายเหตุ',
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _search.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.clear),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: <Widget>[
                      _filter('ทั้งหมด', null),
                      _filter('รอเช็กอิน', 0),
                      _filter('กำลังเข้าพัก', 1),
                      _filter('เช็กเอาต์แล้ว', 2),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(child: _calendarMode ? _calendarView() : _bookingListView()),
      ],
    );
  }

  Widget _bookingListView() => ValueListenableBuilder<int>(
    valueListenable: dbRevision,
    builder: (context, revision, child) => FutureBuilder<List<StayWithRoom>>(
      future: DatabaseHelper.instance.searchStays(
        keyword: _search.text,
        status: _status,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) return _error(snapshot.error);
        final List<StayWithRoom> data = snapshot.data ?? <StayWithRoom>[];
        if (data.isEmpty) {
          return const EmptyState(
            icon: Icons.search_off,
            title: 'ไม่พบ Booking',
            hint: 'ลองเปลี่ยนคำค้นหาหรือตัวกรอง',
          );
        }
        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 100),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final StayWithRoom item = data[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _bookingCard(item),
              );
            },
          ),
        );
      },
    ),
  );

  StayCard _bookingCard(StayWithRoom item) => StayCard(
    data: item,
    onCheckIn: () => _checkIn(item),
    onCheckOut: () => _checkout(item),
    onEdit: () => _edit(item),
    onExtend: () => _extend(item),
    onFeedback: () => _feedback(item),
    onDetails: () => _details(item),
    onDelete: () => _delete(item),
  );

  Widget _calendarToolbar() => AppCard(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    child: Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            IconButton(
              onPressed: () => _shiftMonth(-1),
              icon: const Icon(Icons.chevron_left),
              tooltip: 'เดือนก่อนหน้า',
            ),
            Expanded(
              child: Text(
                formatThaiMonthYear(_calendarMonth),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ),
            IconButton(
              onPressed: () => _shiftMonth(1),
              icon: const Icon(Icons.chevron_right),
              tooltip: 'เดือนถัดไป',
            ),
            TextButton(
              onPressed: _goToCurrentMonth,
              child: const Text('วันนี้'),
            ),
          ],
        ),
        const Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 4,
          children: <Widget>[
            _CalendarLegend(color: AppColors.warning, label: 'รอเช็กอิน'),
            _CalendarLegend(color: AppColors.primary, label: 'กำลังพัก'),
            _CalendarLegend(color: AppColors.success, label: 'เช็กเอาต์แล้ว'),
          ],
        ),
      ],
    ),
  );

  Widget _calendarView() => ValueListenableBuilder<int>(
    valueListenable: dbRevision,
    builder: (context, revision, child) => FutureBuilder<List<StayWithRoom>>(
      future: DatabaseHelper.instance.getStaysForMonth(
        _calendarMonth.year,
        _calendarMonth.month,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) return _error(snapshot.error);
        return _buildCalendar(snapshot.data ?? <StayWithRoom>[]);
      },
    ),
  );

  Widget _buildCalendar(List<StayWithRoom> stays) {
    final DateTime firstDay = DateTime(
      _calendarMonth.year,
      _calendarMonth.month,
    );
    final int leadingEmptyDays = firstDay.weekday - 1;
    final int daysInMonth = DateTime(
      _calendarMonth.year,
      _calendarMonth.month + 1,
      0,
    ).day;
    final int cellCount = ((leadingEmptyDays + daysInMonth + 6) ~/ 7) * 7;
    final List<StayWithRoom> selected = _staysOnDay(
      stays,
      _selectedCalendarDay,
    );
    final String selectedIso = toIsoDate(_selectedCalendarDay);
    final int arrivals = selected
        .where((item) => item.stay.checkInDate == selectedIso)
        .length;
    final int departures = selected
        .where((item) => item.stay.checkOutDate == selectedIso)
        .length;
    final int occupied = selected
        .where(
          (item) =>
              item.stay.checkInDate.compareTo(selectedIso) <= 0 &&
              item.stay.checkOutDate.compareTo(selectedIso) > 0,
        )
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 100),
      children: <Widget>[
        const Row(
          children: <Widget>[
            _WeekdayLabel('จ'),
            _WeekdayLabel('อ'),
            _WeekdayLabel('พ'),
            _WeekdayLabel('พฤ'),
            _WeekdayLabel('ศ'),
            _WeekdayLabel('ส'),
            _WeekdayLabel('อา'),
          ],
        ),
        const SizedBox(height: 4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 0.88,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: cellCount,
          itemBuilder: (context, index) {
            final int dayNumber = index - leadingEmptyDays + 1;
            if (dayNumber < 1 || dayNumber > daysInMonth) {
              return const SizedBox.shrink();
            }
            final DateTime day = DateTime(
              _calendarMonth.year,
              _calendarMonth.month,
              dayNumber,
            );
            final List<StayWithRoom> dayStays = _staysOnDay(stays, day);
            return _calendarCell(day, dayStays);
          },
        ),
        const SizedBox(height: 14),
        AppCard(
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      formatThaiDateFull(_selectedCalendarDay),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'เข้าพัก $occupied ห้อง · เข้า $arrivals · ออก $departures',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${selected.length} รายการ',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (selected.isEmpty)
          const EmptyState(
            icon: Icons.event_available_outlined,
            title: 'วันนี้ไม่มี Booking',
            hint: 'แตะวันอื่น หรือกดปุ่มเปิดรายการเข้าพักเพื่อเพิ่ม Booking',
          )
        else
          ...selected.map(
            (StayWithRoom item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  onTap: () => _details(item),
                  leading: CircleAvatar(
                    backgroundColor: _statusColor(
                      item.stay.status,
                    ).withValues(alpha: 0.12),
                    child: Text(
                      item.roomName,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: _statusColor(item.stay.status),
                      ),
                    ),
                  ),
                  title: Text(
                    item.stay.guestName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(_dayEventLabel(item, selectedIso)),
                  trailing: StatusChip(status: item.stay.status),
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<StayWithRoom> _staysOnDay(List<StayWithRoom> stays, DateTime day) {
    final String iso = toIsoDate(day);
    return stays
        .where(
          (StayWithRoom item) =>
              item.stay.checkInDate.compareTo(iso) <= 0 &&
              item.stay.checkOutDate.compareTo(iso) >= 0,
        )
        .toList();
  }

  Widget _calendarCell(DateTime day, List<StayWithRoom> stays) {
    final bool selected = dateOnly(day) == dateOnly(_selectedCalendarDay);
    final bool today = dateOnly(day) == dateOnly(DateTime.now());
    final Set<int> statuses = stays.map((item) => item.stay.status).toSet();
    return CalendarDayCell(
      day: day.day,
      bookingCount: stays.length,
      statuses: statuses,
      selected: selected,
      today: today,
      onTap: () => setState(() => _selectedCalendarDay = day),
    );
  }

  Color _statusColor(int status) {
    return CalendarDayCell.statusColor(status);
  }

  String _dayEventLabel(StayWithRoom item, String day) {
    if (item.stay.checkInDate == day) {
      return 'เช็กอินวันนี้ · ${item.stay.nights} คืน';
    }
    if (item.stay.checkOutDate == day) return 'เช็กเอาต์วันนี้';
    return 'พักต่อ · ออก ${formatIsoAsThaiDate(item.stay.checkOutDate)}';
  }

  Widget _filter(String label, int? value) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: _status == value,
      onSelected: (_) => setState(() => _status = value),
    ),
  );
  Widget _error(Object? error) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Icon(Icons.error_outline, size: 42, color: AppColors.danger),
        const SizedBox(height: 8),
        Text('โหลดข้อมูลไม่สำเร็จ\n$error', textAlign: TextAlign.center),
        TextButton(
          onPressed: () => setState(() {}),
          child: const Text('ลองใหม่'),
        ),
      ],
    ),
  );
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Center(
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.muted,
        ),
      ),
    ),
  );
}

class _CalendarLegend extends StatelessWidget {
  const _CalendarLegend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
    ],
  );
}
