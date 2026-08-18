// หน้าตารางเข้าพัก ใช้ดูว่าวันไหนมีใครพักบ้าง และเป็นที่ที่ใช้กดเช็คอิน เช็คเอาท์ และลบรายการ
// มีสองโหมดคือดูรายวัน (ค่าเริ่มต้น) กับดูประวัติทั้งหมดรวมรายการที่เช็คเอาท์ไปแล้ว
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../db/database_helper.dart';
import '../models/stay.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';
import '../widgets/stay_card.dart';

class StayListScreen extends StatefulWidget {
  const StayListScreen({super.key});

  @override
  State<StayListScreen> createState() => _StayListScreenState();
}

class _StayListScreenState extends State<StayListScreen> {
  DateTime _selectedDate = dateOnly(DateTime.now());
  bool _showAllHistory = false;

  /// เลื่อนวันทีละหนึ่งวัน ใช้กับปุ่มลูกศรซ้ายขวา
  void _shiftDay(int days) {
    setState(() => _selectedDate = _selectedDate.add(Duration(days: days)));
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(_selectedDate.year - 2),
      lastDate: DateTime(_selectedDate.year + 2),
      helpText: 'เลือกวันที่ต้องการดู',
      cancelText: 'ยกเลิก',
      confirmText: 'ตกลง',
    );
    if (picked != null) setState(() => _selectedDate = dateOnly(picked));
  }

  Future<void> _checkIn(StayWithRoom item) async {
    await DatabaseHelper.instance.checkIn(item.stay.id!);
    if (!mounted) return;
    showAppSnackBar(context, 'เช็คอิน ${item.stay.guestName} เข้าห้อง ${item.roomName} แล้ว');
  }

  Future<void> _checkOut(StayWithRoom item) async {
    await DatabaseHelper.instance.checkOut(item.stay.id!);
    if (!mounted) return;
    showAppSnackBar(context, 'เช็คเอาท์ห้อง ${item.roomName} เรียบร้อย ห้องกลับมาว่างแล้ว');
  }

  /// ถามยืนยันก่อนลบจริง เพราะการลบรายการเข้าพักกู้คืนไม่ได้
  /// และถ้ารายการนั้นกำลังเช็คอินอยู่ การลบจะทำให้ห้องถูกปล่อยว่างทันทีด้วย
  Future<bool> _confirmDelete(StayWithRoom item) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('ยืนยันการลบรายการ'),
          content: Text(
            'ต้องการลบรายการของ ${item.stay.guestName} ห้อง ${item.roomName} ใช่หรือไม่\n\n'
            '${item.stay.status == Stay.statusCheckedIn ? 'รายการนี้กำลังเช็คอินอยู่ ห้องจะถูกเปลี่ยนเป็นว่างทันที' : 'ข้อมูลที่ลบแล้วไม่สามารถกู้คืนได้'}',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('ยกเลิก'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.occupied),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('ลบรายการ'),
            ),
          ],
        );
      },
    );
    return confirmed ?? false;
  }

  Future<void> _delete(StayWithRoom item) async {
    await DatabaseHelper.instance.deleteStay(item.stay.id!);
    if (!mounted) return;
    showAppSnackBar(context, 'ลบรายการของ ${item.stay.guestName} แล้ว');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _buildToolbar(),
        Expanded(
          child: ValueListenableBuilder<int>(
            valueListenable: dbRevision,
            builder: (BuildContext context, int revision, Widget? child) {
              return FutureBuilder<List<StayWithRoom>>(
                // โหมดประวัติดึงทุกรายการ ส่วนโหมดรายวันดึงเฉพาะรายการที่ครอบคลุมวันนั้น
                future: _showAllHistory
                    ? DatabaseHelper.instance.getAllStays()
                    : DatabaseHelper.instance.getStaysOnDate(toIsoDate(_selectedDate)),
                builder: (
                  BuildContext context,
                  AsyncSnapshot<List<StayWithRoom>> snapshot,
                ) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final List<StayWithRoom> stays = snapshot.data ?? <StayWithRoom>[];
                  if (stays.isEmpty) {
                    return EmptyState(
                      icon: Icons.event_available_outlined,
                      title: _showAllHistory
                          ? 'ยังไม่มีประวัติการเข้าพัก'
                          : 'ไม่มีผู้เข้าพักในวันที่เลือก',
                      hint: 'กดปุ่มเปิดรายการเข้าพักด้านล่างเพื่อเพิ่มรายการใหม่',
                    );
                  }
                  return _buildList(stays);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// แถบเลือกวันและสวิตช์สลับโหมดดูประวัติ
  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      child: AppCard(
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                IconButton(
                  // ปิดปุ่มเลื่อนวันในโหมดประวัติ เพราะโหมดนั้นไม่ได้กรองตามวันอยู่แล้ว
                  onPressed: _showAllHistory ? null : () => _shiftDay(-1),
                  icon: const Icon(Icons.chevron_left),
                  color: AppColors.primaryDark,
                ),
                Expanded(
                  child: InkWell(
                    onTap: _showAllHistory ? null : _pickDate,
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        children: <Widget>[
                          Text(
                            _showAllHistory
                                ? 'ประวัติทั้งหมด'
                                : relativeDayLabel(_selectedDate),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _showAllHistory
                                ? 'รวมรายการที่เช็คเอาท์แล้ว'
                                : formatThaiDateFull(_selectedDate),
                            style: const TextStyle(fontSize: 12, color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _showAllHistory ? null : () => _shiftDay(1),
                  icon: const Icon(Icons.chevron_right),
                  color: AppColors.primaryDark,
                ),
              ],
            ),
            const Divider(height: 18),
            Row(
              children: <Widget>[
                const Icon(Icons.history, size: 18, color: AppColors.muted),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'ดูประวัติทั้งหมด',
                    style: TextStyle(fontSize: 14, color: AppColors.ink),
                  ),
                ),
                Switch(
                  value: _showAllHistory,
                  activeThumbColor: AppColors.primary,
                  onChanged: (bool value) => setState(() => _showAllHistory = value),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// รายการการ์ด แต่ละใบห่อด้วย Dismissible ให้ปัดไปทางซ้ายเพื่อลบ
  Widget _buildList(List<StayWithRoom> stays) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 96),
      itemCount: stays.length,
      itemBuilder: (BuildContext context, int index) {
        final StayWithRoom item = stays[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Dismissible(
            // ใช้ id ของรายการเป็นกุญแจ เพื่อให้ Flutter รู้ว่าการ์ดใบไหนถูกปัดออกไป
            // แม้ลำดับในรายการจะเปลี่ยนหลังโหลดข้อมูลใหม่
            key: ValueKey<int>(item.stay.id!),
            direction: DismissDirection.endToStart,
            background: _buildDeleteBackground(),
            // ถามยืนยันก่อน ถ้าผู้ใช้กดยกเลิก การ์ดจะเด้งกลับที่เดิมโดยไม่มีอะไรเกิดขึ้น
            confirmDismiss: (DismissDirection direction) => _confirmDelete(item),
            onDismissed: (DismissDirection direction) => _delete(item),
            child: StayCard(
              data: item,
              onCheckIn: () => _checkIn(item),
              onCheckOut: () => _checkOut(item),
            ),
          ),
        );
      },
    );
  }

  /// พื้นหลังสีส้มที่โผล่ขึ้นมาระหว่างปัดการ์ด บอกให้รู้ว่ากำลังจะลบ
  Widget _buildDeleteBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.occupiedBg,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.occupiedBorder, width: 0.5),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Text(
            'ลบรายการ',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.occupied,
            ),
          ),
          SizedBox(width: 8),
          Icon(Icons.delete_outline, color: AppColors.occupied),
        ],
      ),
    );
  }
}
