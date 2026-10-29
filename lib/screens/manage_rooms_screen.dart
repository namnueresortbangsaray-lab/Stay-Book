// หน้าจัดการห้องพัก ใช้เพิ่ม แก้ไข และลบห้อง
// แยกออกจากหน้าผังห้องโดยตั้งใจ เพราะเป็นงานตั้งค่าที่ทำนาน ๆ ครั้ง
// ไม่ใช่งานประจำวันแบบการรับแขก จึงไม่ควรมาปนกับหน้าที่ใช้ทุกวัน
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../db/database_helper.dart';
import '../models/room.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';

class ManageRoomsScreen extends StatelessWidget {
  const ManageRoomsScreen({super.key});

  /// เปิดกล่องฟอร์มห้อง ใช้ทั้งตอนเพิ่มใหม่และตอนแก้ไข
  /// ส่ง existing เข้าไปเมื่อเป็นการแก้ไข ฟอร์มจะเติมค่าเดิมให้อัตโนมัติ
  Future<void> _openRoomDialog(BuildContext context, {Room? existing}) async {
    final Room? result = await showDialog<Room>(
      context: context,
      builder: (BuildContext dialogContext) => _RoomFormDialog(existing: existing),
    );
    if (result == null || !context.mounted) return;

    if (existing == null) {
      await DatabaseHelper.instance.insertRoom(result);
      if (!context.mounted) return;
      showAppSnackBar(context, 'เพิ่มห้อง ${result.name} เรียบร้อย');
    } else {
      await DatabaseHelper.instance.updateRoom(result);
      if (!context.mounted) return;
      showAppSnackBar(context, 'บันทึกการแก้ไขห้อง ${result.name} แล้ว');
    }
  }

  /// ถามยืนยันก่อนลบห้อง พร้อมบอกจำนวนประวัติที่จะหายไปด้วย
  /// ต้องบอกตัวเลขจริง เพราะการลบห้องจะลบรายการเข้าพักทั้งหมดของห้องนั้นทิ้งไปด้วย
  /// ผู้ใช้ควรรู้ผลกระทบก่อนตัดสินใจ ไม่ใช่มารู้ทีหลังตอนหาประวัติไม่เจอ
  Future<void> _confirmDelete(BuildContext context, Room room) async {
    final int stayCount = await DatabaseHelper.instance.countStaysOfRoom(room.id!);
    if (!context.mounted) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('ลบห้อง ${room.name}'),
          content: Text(
            stayCount == 0
                ? 'ห้องนี้ยังไม่มีประวัติการเข้าพัก ต้องการลบใช่หรือไม่'
                : 'ห้องนี้มีประวัติการเข้าพัก $stayCount รายการ\n'
                    'การลบห้องจะลบประวัติทั้งหมดนี้ไปด้วย และกู้คืนไม่ได้',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('ยกเลิก'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.occupied),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('ลบห้อง'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;

    await DatabaseHelper.instance.deleteRoom(room.id!);
    if (!context.mounted) return;
    showAppSnackBar(context, 'ลบห้อง ${room.name} แล้ว');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: ValueListenableBuilder<int>(
        valueListenable: dbRevision,
        builder: (BuildContext context, int revision, Widget? child) {
          return FutureBuilder<List<Room>>(
            future: DatabaseHelper.instance.getAllRooms(),
            builder: (BuildContext context, AsyncSnapshot<List<Room>> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final List<Room> rooms = snapshot.data ?? <Room>[];
              if (rooms.isEmpty) {
                return const EmptyState(
                  icon: Icons.meeting_room_outlined,
                  title: 'ยังไม่มีห้องพัก',
                  hint: 'กดปุ่มเพิ่มห้องเพื่อสร้างห้องแรก',
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 96),
                itemCount: rooms.length,
                itemBuilder: (BuildContext context, int index) {
                  final Room room = rooms[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _RoomRow(
                      room: room,
                      onEdit: () => _openRoomDialog(context, existing: room),
                      onDelete: () => _confirmDelete(context, room),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openRoomDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มห้อง'),
      ),
    );
  }
}

/// หนึ่งแถวของห้องในรายการ พร้อมปุ่มแก้ไขและลบ
class _RoomRow extends StatelessWidget {
  const _RoomRow({
    required this.room,
    required this.onEdit,
    required this.onDelete,
  });

  final Room room;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: room.isOccupied ? AppColors.occupiedBg : AppColors.vacantBg,
              borderRadius: BorderRadius.circular(AppRadius.medium),
              border: Border.all(
                color: room.isOccupied ? AppColors.occupiedBorder : AppColors.vacantBorder,
                width: 0.5,
              ),
            ),
            child: Text(
              room.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: room.isOccupied ? AppColors.occupied : AppColors.primaryDark,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${room.zone} · ${room.type}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatBaht(room.price)}/คืน · พื้นฐาน ${room.baseGuests} ท่าน · '
                  'สูงสุด ${room.maxGuests} ท่าน'
                  '${room.extraGuestFee > 0 ? ' · คนเพิ่ม ${formatBaht(room.extraGuestFee)}' : ''}',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            color: AppColors.primaryDark,
            tooltip: 'แก้ไขห้อง',
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
            color: AppColors.occupied,
            tooltip: 'ลบห้อง',
          ),
        ],
      ),
    );
  }
}

/// กล่องฟอร์มกรอกข้อมูลห้อง ใช้ร่วมกันทั้งการเพิ่มและการแก้ไข
///
/// คืนค่าเป็นอ็อบเจกต์ Room กลับไปให้หน้าจอเป็นคนสั่งบันทึกลงฐานข้อมูล
/// กล่องนี้จึงไม่ต้องรู้จักฐานข้อมูลเลย ทำหน้าที่รับข้อมูลกับตรวจความถูกต้องอย่างเดียว
class _RoomFormDialog extends StatefulWidget {
  const _RoomFormDialog({this.existing});

  final Room? existing;

  @override
  State<_RoomFormDialog> createState() => _RoomFormDialogState();
}

class _RoomFormDialogState extends State<_RoomFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _zone =
      TextEditingController(text: widget.existing?.zone ?? 'อาคารหลัก');
  late final TextEditingController _type =
      TextEditingController(text: widget.existing?.type ?? 'เตียงคู่');
  late final TextEditingController _price =
      TextEditingController(text: _numberText(widget.existing?.price));
  late final TextEditingController _baseGuests =
      TextEditingController(text: '${widget.existing?.baseGuests ?? 2}');
  late final TextEditingController _maxGuests =
      TextEditingController(text: '${widget.existing?.maxGuests ?? 2}');
  late final TextEditingController _extraGuestFee =
      TextEditingController(text: _numberText(widget.existing?.extraGuestFee));

  /// แปลงตัวเลขให้เป็นข้อความสำหรับใส่ในช่องกรอก โดยตัด .0 ที่ไม่จำเป็นออก
  static String _numberText(double? value) {
    if (value == null) return '';
    return value == value.roundToDouble()
        ? value.round().toString()
        : value.toString();
  }

  @override
  void dispose() {
    _name.dispose();
    _zone.dispose();
    _type.dispose();
    _price.dispose();
    _baseGuests.dispose();
    _maxGuests.dispose();
    _extraGuestFee.dispose();
    super.dispose();
  }

  /// ตรวจช่องที่ต้องเป็นตัวเลขไม่ติดลบ ใช้ร่วมกันหลายช่องเพื่อไม่ให้เขียนซ้ำ
  String? _validateNumber(String? value, {required String label, int minimum = 0}) {
    final String text = (value ?? '').trim();
    if (text.isEmpty) return 'กรุณากรอก$label';
    final double? parsed = double.tryParse(text);
    if (parsed == null) return '$labelต้องเป็นตัวเลข';
    if (parsed < minimum) return '$labelต้องไม่น้อยกว่า $minimum';
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final int base = int.parse(_baseGuests.text.trim());
    final int max = int.parse(_maxGuests.text.trim());
    if (max < base) {
      showAppSnackBar(
        context,
        'จำนวนคนสูงสุดต้องไม่น้อยกว่าจำนวนคนพื้นฐาน',
        isError: true,
      );
      return;
    }

    // ใช้ copyWith ตอนแก้ไข เพื่อรักษา id กับ sort_order เดิมไว้ ไม่ให้ลำดับห้องสลับ
    final Room room = widget.existing?.copyWith(
          name: _name.text.trim(),
          zone: _zone.text.trim(),
          type: _type.text.trim(),
          price: double.parse(_price.text.trim()),
          baseGuests: base,
          maxGuests: max,
          extraGuestFee: double.parse(_extraGuestFee.text.trim()),
        ) ??
        Room(
          name: _name.text.trim(),
          zone: _zone.text.trim(),
          type: _type.text.trim(),
          price: double.parse(_price.text.trim()),
          baseGuests: base,
          maxGuests: max,
          extraGuestFee: double.parse(_extraGuestFee.text.trim()),
        );

    Navigator.of(context).pop(room);
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.existing != null;

    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(isEditing ? 'แก้ไขห้อง ${widget.existing!.name}' : 'เพิ่มห้องพักใหม่'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'ชื่อห้อง เช่น 11 หรือ B3'),
                  validator: (String? value) =>
                      (value ?? '').trim().isEmpty ? 'กรุณากรอกชื่อห้อง' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _zone,
                  decoration: const InputDecoration(labelText: 'โซน'),
                  validator: (String? value) =>
                      (value ?? '').trim().isEmpty ? 'กรุณากรอกโซน' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _type,
                  decoration: const InputDecoration(labelText: 'ประเภทห้อง'),
                  validator: (String? value) =>
                      (value ?? '').trim().isEmpty ? 'กรุณากรอกประเภทห้อง' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _price,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'ราคาต่อคืน (บาท)'),
                  validator: (String? value) =>
                      _validateNumber(value, label: 'ราคา', minimum: 1),
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextFormField(
                        controller: _baseGuests,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'คนพื้นฐาน'),
                        validator: (String? value) =>
                            _validateNumber(value, label: 'จำนวนคนพื้นฐาน', minimum: 1),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _maxGuests,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'คนสูงสุด'),
                        validator: (String? value) =>
                            _validateNumber(value, label: 'จำนวนคนสูงสุด', minimum: 1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _extraGuestFee,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'ค่าคนเพิ่ม ต่อคน ต่อคืน (บาท)',
                  ),
                  validator: (String? value) =>
                      _validateNumber(value, label: 'ค่าคนเพิ่ม'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ยกเลิก'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(isEditing ? 'บันทึกการแก้ไข' : 'เพิ่มห้อง'),
        ),
      ],
    );
  }
}
