// กล่องงานต่อเวลาพักและตรวจห้องก่อนเช็กเอาต์ ใช้ร่วมกันจากหลายหน้าจอ
import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../models/checkout_inspection.dart';
import '../models/room.dart';
import '../models/stay.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

Future<bool> showExtendStayDialog(
  BuildContext context,
  StayWithRoom item,
) async {
  final List<Room> rooms = await DatabaseHelper.instance.getAllRooms();
  final Room room = rooms.firstWhere(
    (Room value) => value.id == item.stay.roomId,
  );
  if (!context.mounted) return false;
  DateTime newCheckout = parseIsoDate(
    item.stay.checkOutDate,
  ).add(const Duration(days: 1));
  double discount = item.stay.discountAmount;
  final bool? saved = await showDialog<bool>(
    context: context,
    builder: (BuildContext outer) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          final PriceBreakdown price = PriceBreakdown.calculate(
            room: room,
            guests: item.stay.guests,
            checkInDate: item.stay.checkInDate,
            checkOutDate: toIsoDate(newCheckout),
            extraBed: item.stay.hasExtraBed,
            petCount: item.stay.petCount,
            discountAmount: discount,
            depositAmount: item.stay.depositAmount,
            depositPaid: item.stay.depositPaid,
          );
          return AlertDialog(
            title: const Text('ต่อระยะเวลาพัก'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'ห้อง ${item.roomName} · วันออกเดิม ${formatIsoAsThaiDate(item.stay.checkOutDate)}',
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    tileColor: AppColors.surfaceBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: () async {
                      final DateTime? value = await showDatePicker(
                        context: context,
                        initialDate: newCheckout,
                        firstDate: parseIsoDate(
                          item.stay.checkOutDate,
                        ).add(const Duration(days: 1)),
                        lastDate: DateTime.now().add(
                          const Duration(days: 1095),
                        ),
                      );
                      if (value != null) setState(() => newCheckout = value);
                    },
                    title: Text('วันออกใหม่ ${formatThaiDate(newCheckout)}'),
                    trailing: const Icon(Icons.edit_calendar),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: formatMoney(discount),
                    keyboardType: TextInputType.number,
                    onChanged: (v) =>
                        setState(() => discount = double.tryParse(v) ?? 0),
                    decoration: const InputDecoration(
                      labelText: 'ส่วนลดเดิม/ใหม่ (บาท)',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'เพิ่ม ${nightsBetween(item.stay.checkOutDate, toIsoDate(newCheckout))} คืน',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'ยอดใหม่ ${formatBaht(price.total)} · คงเหลือ ${formatBaht(price.balanceDue)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(outer, false),
                child: const Text('ยกเลิก'),
              ),
              FilledButton(
                onPressed: () async {
                  if (discount < 0 || discount > price.grossTotal) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ส่วนลดไม่ถูกต้อง')),
                    );
                    return;
                  }
                  try {
                    await DatabaseHelper.instance.extendStay(
                      item.stay.copyWith(
                        checkOutDate: toIsoDate(newCheckout),
                        totalAmount: price.total,
                        petFee: price.petTotal,
                        discountAmount: discount,
                      ),
                    );
                    if (outer.mounted) Navigator.pop(outer, true);
                  } catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(error.toString())));
                    }
                  }
                },
                child: const Text('บันทึก'),
              ),
            ],
          );
        },
      );
    },
  );
  return saved ?? false;
}

Future<CheckoutInspection?> showCheckoutInspectionDialog(
  BuildContext context,
  int stayId,
) {
  bool? keyReturned, roomClean, equipmentComplete, noDamage, minibarChecked;
  final TextEditingController note = TextEditingController();
  return showDialog<CheckoutInspection>(
    context: context,
    builder: (BuildContext outer) => StatefulBuilder(
      builder: (context, setState) {
        Widget answer(String label, bool? value, ValueChanged<bool?> changed) =>
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Wrap(
                  spacing: 8,
                  children: <Widget>[
                    ChoiceChip(
                      label: const Text('เรียบร้อย / ใช่'),
                      selected: value == true,
                      onSelected: (_) => changed(true),
                    ),
                    ChoiceChip(
                      label: const Text('ไม่เรียบร้อย / ไม่'),
                      selected: value == false,
                      onSelected: (_) => changed(false),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            );
        return AlertDialog(
          title: const Text('Checklist ก่อนเช็กเอาต์'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                answer(
                  'คืนกุญแจแล้ว',
                  keyReturned,
                  (v) => setState(() => keyReturned = v),
                ),
                answer(
                  'ตรวจสอบความสะอาดแล้ว',
                  roomClean,
                  (v) => setState(() => roomClean = v),
                ),
                answer(
                  'อุปกรณ์ครบ',
                  equipmentComplete,
                  (v) => setState(() => equipmentComplete = v),
                ),
                answer(
                  'ไม่พบความเสียหาย',
                  noDamage,
                  (v) => setState(() => noDamage = v),
                ),
                answer(
                  'ตรวจสอบมินิบาร์แล้ว',
                  minibarChecked,
                  (v) => setState(() => minibarChecked = v),
                ),
                TextField(
                  controller: note,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'หมายเหตุ / รายละเอียดความเสียหาย',
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(outer),
              child: const Text('ยกเลิก'),
            ),
            FilledButton(
              onPressed: () {
                if (<bool?>[
                  keyReturned,
                  roomClean,
                  equipmentComplete,
                  noDamage,
                  minibarChecked,
                ].any((v) => v == null)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('กรุณาตอบทุกหัวข้อ')),
                  );
                  return;
                }
                if (noDamage == false && note.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('กรุณาระบุรายละเอียดความเสียหาย'),
                    ),
                  );
                  return;
                }
                Navigator.pop(
                  outer,
                  CheckoutInspection(
                    stayId: stayId,
                    keyReturned: keyReturned!,
                    roomClean: roomClean!,
                    equipmentComplete: equipmentComplete!,
                    noDamage: noDamage!,
                    minibarChecked: minibarChecked!,
                    inspectionNote: note.text.trim().isEmpty
                        ? null
                        : note.text.trim(),
                    inspectedAt: DateTime.now().toIso8601String(),
                  ),
                );
              },
              child: const Text('ยืนยันเช็กเอาต์'),
            ),
          ],
        );
      },
    ),
  );
}
