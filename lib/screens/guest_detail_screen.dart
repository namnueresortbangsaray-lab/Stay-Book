// รายละเอียดโปรไฟล์ลูกค้า สถิติสะสม และประวัติ Booking
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../config.dart';
import '../db/database_helper.dart';
import '../models/guest.dart';
import '../models/stay.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';
import 'booking_form_screen.dart';

class GuestDetailScreen extends StatelessWidget {
  const GuestDetailScreen({super.key, required this.guestId});
  final int guestId;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('ประวัติลูกค้า')),
    body: ValueListenableBuilder<int>(
      valueListenable: dbRevision,
      builder: (context, revision, child) => FutureBuilder<GuestHistory>(
        future: DatabaseHelper.instance.getGuestHistory(guestId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('โหลดไม่สำเร็จ\n${snapshot.error}'));
          }
          final h = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            h.summary.guest.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        if (h.summary.guest.isRegular)
                          const Chip(label: Text('ลูกค้าประจำ')),
                      ],
                    ),
                    Text(h.summary.guest.phone),
                    Text(
                      h.summary.guest.customerType,
                      style: const TextStyle(color: AppColors.primaryDark),
                    ),
                    if (h.summary.guest.customerNote?.isNotEmpty == true)
                      Text('โน้ตถาวร: ${h.summary.guest.customerNote}'),
                    if (h.summary.guest.preferences?.isNotEmpty == true)
                      Text('ความต้องการ: ${h.summary.guest.preferences}'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: <Widget>[
                        OutlinedButton.icon(
                          onPressed: () => _edit(context, h.summary.guest),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('แก้ไข'),
                        ),
                        FilledButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookingFormScreen(
                                initialGuest: h.summary.guest,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('สร้าง Booking'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GuestStatistics(
                children: <Widget>[
                  StatCard(
                    icon: Icons.hotel,
                    label: 'เข้าพักสำเร็จ',
                    value: '${h.summary.completedStays} ครั้ง',
                    accent: AppColors.primary,
                  ),
                  StatCard(
                    icon: Icons.nights_stay,
                    label: 'คืนสะสม',
                    value: '${h.summary.totalNights} คืน',
                    accent: AppColors.primary,
                  ),
                  StatCard(
                    icon: Icons.payments_outlined,
                    label: 'ยอดสะสม',
                    value: formatBaht(h.summary.lifetimeValue),
                    accent: AppColors.success,
                  ),
                  StatCard(
                    icon: Icons.discount_outlined,
                    label: 'ส่วนลดสะสม',
                    value: formatBaht(h.summary.totalDiscount),
                    accent: AppColors.warning,
                  ),
                ],
              ),
              if (!h.summary.guest.isRegular &&
                  h.summary.completedStays >=
                      ResortConfig.regularGuestStayThreshold)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: AppCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.workspace_premium,
                        color: AppColors.warning,
                      ),
                      title: const Text('เสนอให้ตั้งเป็นลูกค้าประจำ'),
                      subtitle: Text(
                        'เข้าพักสำเร็จแล้ว ${h.summary.completedStays} ครั้ง',
                      ),
                      trailing: TextButton(
                        onPressed: () => DatabaseHelper.instance.updateGuest(
                          h.summary.guest.copyWith(
                            isRegular: true,
                            customerType: 'ลูกค้าประจำ',
                            updatedAt: DateTime.now().toIso8601String(),
                          ),
                        ),
                        child: const Text('ตั้งค่า'),
                      ),
                    ),
                  ),
                ),
              const SectionTitle(title: 'ประวัติ Booking'),
              if (h.stays.isEmpty)
                const Text('ยังไม่มีประวัติ')
              else
                ...h.stays.map(
                  (StayWithRoom item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'ห้อง ${item.roomName} · ${formatIsoAsThaiDate(item.stay.checkInDate)} – ${formatIsoAsThaiDate(item.stay.checkOutDate)}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${item.stay.nights} คืน · ${item.stay.guests} คน${item.stay.hasPet ? ' · ${item.stay.petType} ${item.stay.petCount} ตัว' : ''}',
                          ),
                          Text(
                            'สุทธิ ${formatBaht(item.stay.totalAmount)} · ส่วนลด ${formatBaht(item.stay.discountAmount)} · มัดจำ ${formatBaht(item.stay.depositAmount)}',
                          ),
                          if (item.stay.note != null)
                            Text(
                              'หมายเหตุ: ${item.stay.note}',
                              style: const TextStyle(color: AppColors.muted),
                            ),
                          if (item.feedbackRating != null)
                            Text(
                              'Feedback ${item.feedbackRating} / 5',
                              style: const TextStyle(color: AppColors.warning),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
  Future<void> _edit(BuildContext context, Guest guest) async {
    final result = await showDialog<Guest>(
      context: context,
      builder: (_) => _GuestDialog(guest: guest),
    );
    if (result != null) await DatabaseHelper.instance.updateGuest(result);
  }
}

/// ให้การ์ดสูงตามเนื้อหา รองรับจอแคบและการขยายตัวอักษรของระบบ
class GuestStatistics extends StatelessWidget {
  const GuestStatistics({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Wrap(
      spacing: 8,
      runSpacing: 8,
      children: children
          .map(
            (child) =>
                SizedBox(width: (constraints.maxWidth - 8) / 2, child: child),
          )
          .toList(),
    ),
  );
}

class _GuestDialog extends StatefulWidget {
  const _GuestDialog({required this.guest});
  final Guest guest;
  @override
  State<_GuestDialog> createState() => _GuestDialogState();
}

class _GuestDialogState extends State<_GuestDialog> {
  late final TextEditingController name = TextEditingController(
        text: widget.guest.name,
      ),
      phone = TextEditingController(text: widget.guest.phone),
      note = TextEditingController(text: widget.guest.customerNote),
      preferences = TextEditingController(text: widget.guest.preferences);
  late final TextEditingController otherType = TextEditingController(
    text: types.contains(widget.guest.customerType)
        ? ''
        : widget.guest.customerType,
  );
  late String type = widget.guest.customerType;
  late bool regular = widget.guest.isRegular;
  static const types = <String>[
    'ลูกค้าใหม่',
    'ลูกค้าทั่วไป',
    'ลูกค้าประจำ',
    'ลูกค้า VIP',
    'ลูกค้าองค์กร',
    'ลูกค้ากลุ่มหรือทัวร์',
    'ลูกค้าจากตัวแทน',
    'อื่น ๆ',
  ];

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    note.dispose();
    preferences.dispose();
    otherType.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('แก้ไขข้อมูลลูกค้า'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'ชื่อ'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: phone,
            decoration: const InputDecoration(labelText: 'เบอร์โทร'),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: types.contains(type) ? type : 'อื่น ๆ',
            items: types
                .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                .toList(),
            onChanged: (v) => setState(() => type = v!),
            decoration: const InputDecoration(labelText: 'ประเภทลูกค้า'),
          ),
          if (type == 'อื่น ๆ') ...<Widget>[
            const SizedBox(height: 8),
            TextField(
              controller: otherType,
              decoration: const InputDecoration(labelText: 'ระบุประเภทลูกค้า'),
            ),
          ],
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: regular,
            onChanged: (v) => setState(() => regular = v ?? false),
            title: const Text('ลูกค้าประจำ'),
          ),
          TextField(
            controller: note,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'โน้ตถาวร'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: preferences,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'ความต้องการ/ความชอบ'),
          ),
        ],
      ),
    ),
    actions: <Widget>[
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('ยกเลิก'),
      ),
      FilledButton(
        onPressed: () {
          final normalized = normalizePhone(phone.text);
          if (name.text.trim().length < 2 || normalized.length < 9) return;
          Navigator.pop(
            context,
            widget.guest.copyWith(
              name: name.text.trim(),
              phone: phone.text.trim(),
              normalizedPhone: normalized,
              customerType: type == 'อื่น ๆ' && otherType.text.trim().isNotEmpty
                  ? otherType.text.trim()
                  : type,
              isRegular: regular,
              customerNote: note.text.trim(),
              preferences: preferences.text.trim(),
              updatedAt: DateTime.now().toIso8601String(),
            ),
          );
        },
        child: const Text('บันทึก'),
      ),
    ],
  );
}
