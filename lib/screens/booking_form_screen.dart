// ฟอร์มเปิดรายการเข้าพัก เป็นหน้าที่ซับซ้อนที่สุดของแอป
//
// หน้าที่หลักสามอย่าง
//   1. ให้กรอกข้อมูลแขกพร้อมตรวจความถูกต้องทุกช่องด้วย Form + validator
//   2. แสดงเฉพาะห้องที่ว่างจริงตลอดช่วงวันที่เลือก ไม่ให้เลือกห้องที่จองไม่ได้ตั้งแต่ต้น
//   3. คิดเงินให้เห็นที่มาของทุกบรรทัด และคิดใหม่ทันทีทุกครั้งที่ข้อมูลเปลี่ยน
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config.dart';
import '../db/database_helper.dart';
import '../models/room.dart';
import '../models/stay.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';

class BookingFormScreen extends StatefulWidget {
  const BookingFormScreen({super.key, this.initialRoomId});

  /// ห้องที่ถูกเลือกไว้ล่วงหน้า ส่งมาจากการแตะการ์ดห้องว่างในหน้าผังห้อง
  /// เพื่อลดขั้นตอนให้พนักงานไม่ต้องเลือกห้องซ้ำอีกครั้ง
  final int? initialRoomId;

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  /// ค่าเริ่มต้นคือเข้าวันนี้ออกพรุ่งนี้ ซึ่งเป็นกรณีที่พบบ่อยที่สุดหน้าเคาน์เตอร์
  late DateTime _checkIn = dateOnly(DateTime.now());
  late DateTime _checkOut = dateOnly(DateTime.now()).add(const Duration(days: 1));

  List<Room> _availableRooms = <Room>[];
  Room? _selectedRoom;
  int _guests = 2;
  bool _extraBed = false;
  bool _checkInNow = false;
  bool _loadingRooms = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableRooms(preferredRoomId: widget.initialRoomId);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// โหลดรายชื่อห้องที่ว่างตลอดช่วงวันที่เลือกไว้ตอนนี้
  ///
  /// เรียกทุกครั้งที่ช่วงวันเปลี่ยน เพราะห้องที่ว่างสำหรับสัปดาห์นี้อาจไม่ว่างในสัปดาห์หน้า
  /// ถ้าห้องที่เลือกค้างไว้หลุดออกจากรายการ ต้องล้างค่าที่เลือกและบอกผู้ใช้ให้รู้ตัว
  /// ไม่ใช่ปล่อยให้กดบันทึกแล้วค่อยเด้งข้อความว่าจองไม่ได้
  Future<void> _loadAvailableRooms({int? preferredRoomId}) async {
    setState(() => _loadingRooms = true);

    final List<Room> rooms = await DatabaseHelper.instance.getRoomsForBooking(
      toIsoDate(_checkIn),
      toIsoDate(_checkOut),
    );
    if (!mounted) return;

    final int? targetId = preferredRoomId ?? _selectedRoom?.id;
    Room? keptRoom;
    for (final Room room in rooms) {
      if (room.id == targetId) keptRoom = room;
    }
    final bool selectionLost = _selectedRoom != null && keptRoom == null;

    setState(() {
      _availableRooms = rooms;
      _selectedRoom = keptRoom;
      // ถ้าห้องใหม่รับคนได้น้อยกว่าที่กรอกไว้ ต้องลดจำนวนคนลงให้อยู่ในขอบเขตของห้อง
      if (keptRoom != null && _guests > keptRoom.maxGuests) {
        _guests = keptRoom.maxGuests;
      }
      _loadingRooms = false;
    });

    if (selectionLost) {
      showAppSnackBar(
        context,
        'ห้องที่เลือกไว้ไม่ว่างในช่วงวันใหม่ กรุณาเลือกห้องอีกครั้ง',
        isError: true,
      );
    }
  }

  /// เปิดปฏิทินแบบเลือกช่วง ให้เลือกวันเช็คอินกับวันเช็คเอาท์ในครั้งเดียว
  ///
  /// ถ้าผู้ใช้เลือกวันเดียวกันทั้งสองฝั่ง จะถูกดันวันออกไปเป็นวันถัดไปให้อัตโนมัติ
  /// เพราะการเข้าพักอย่างน้อยต้องเป็นหนึ่งคืนเสมอ ระบบนี้ไม่รองรับการขายแบบรายชั่วโมง
  Future<void> _pickDateRange() async {
    final DateTime now = dateOnly(DateTime.now());
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      initialDateRange: DateTimeRange(start: _checkIn, end: _checkOut),
      helpText: 'เลือกวันเช็คอิน และวันเช็คเอาท์',
      saveText: 'ตกลง',
      cancelText: 'ยกเลิก',
      confirmText: 'ตกลง',
    );
    if (picked == null) return;

    final DateTime start = dateOnly(picked.start);
    DateTime end = dateOnly(picked.end);
    if (!end.isAfter(start)) end = start.add(const Duration(days: 1));

    setState(() {
      _checkIn = start;
      _checkOut = end;
    });
    await _loadAvailableRooms();
  }

  /// รายละเอียดการคิดเงินตามค่าที่กรอกอยู่ตอนนี้
  /// เป็น getter จึงถูกคำนวณใหม่ทุกครั้งที่หน้าจอ build ใหม่
  /// ผลคือยอดเงินอัปเดตทันทีทุกครั้งที่เปลี่ยนห้อง วัน จำนวนคน หรือติ๊กเตียงเสริม
  PriceBreakdown? get _breakdown {
    final Room? room = _selectedRoom;
    if (room == null) return null;
    return PriceBreakdown.calculate(
      room: room,
      guests: _guests,
      checkInDate: toIsoDate(_checkIn),
      checkOutDate: toIsoDate(_checkOut),
      extraBed: _extraBed,
    );
  }

  /// ตรวจสอบและบันทึกรายการเข้าพัก
  ///
  /// ต้องเรียก hasOverlap อีกครั้งก่อนบันทึกเสมอ ถึงแม้ดรอปดาวน์จะกรองห้องมาให้แล้ว
  /// เพราะระหว่างที่ฟอร์มเปิดค้างไว้ อาจมีการเปิดรายการอื่นทับช่วงวันเดียวกันไปแล้ว
  /// การเช็คซ้ำตรงนี้คือด่านสุดท้ายที่กันข้อมูลชนกันจริง ๆ
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final Room? room = _selectedRoom;
    if (room == null) {
      showAppSnackBar(context, 'กรุณาเลือกห้องพัก', isError: true);
      return;
    }

    setState(() => _saving = true);

    final String checkInIso = toIsoDate(_checkIn);
    final String checkOutIso = toIsoDate(_checkOut);

    final bool overlap = await DatabaseHelper.instance.hasOverlap(
      room.id!,
      checkInIso,
      checkOutIso,
    );
    if (!mounted) return;

    if (overlap) {
      setState(() => _saving = false);
      showAppSnackBar(
        context,
        'ห้อง ${room.name} มีคนจองในช่วงวันดังกล่าวแล้ว',
        isError: true,
      );
      await _loadAvailableRooms();
      return;
    }

    final PriceBreakdown breakdown = _breakdown!;
    final Stay stay = Stay(
      guestName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      roomId: room.id!,
      checkInDate: checkInIso,
      checkOutDate: checkOutIso,
      guests: _guests,
      extraBed: _extraBed ? 1 : 0,
      totalAmount: breakdown.total,
      // เปิดสวิตช์เช็คอินทันทีคือแขกยืนอยู่ตรงหน้าแล้ว จึงบันทึกเป็นสถานะเช็คอิน
      // ปิดไว้คือการจองล่วงหน้า ห้องยังว่างให้คนอื่นเห็นจนกว่าแขกจะมาถึง
      status: _checkInNow ? Stay.statusCheckedIn : Stay.statusBooked,
      note: _noteController.text.trim(),
      createdAt: DateTime.now().toIso8601String(),
    );

    await DatabaseHelper.instance.insertStay(stay);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final PriceBreakdown? breakdown = _breakdown;

    return Scaffold(
      appBar: AppBar(title: const Text('เปิดรายการเข้าพัก')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: <Widget>[
            const SectionTitle(title: 'ข้อมูลผู้เข้าพัก'),
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'ชื่อผู้เข้าพัก',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (String? value) {
                final String text = (value ?? '').trim();
                if (text.isEmpty) return 'กรุณากรอกชื่อผู้เข้าพัก';
                if (text.length < 2) return 'ชื่อสั้นเกินไป ต้องมีอย่างน้อย 2 ตัวอักษร';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              // จำกัดให้พิมพ์ได้เฉพาะตัวเลขกับขีด กันข้อมูลเบอร์โทรที่ใช้ติดต่อจริงไม่ได้
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')),
              ],
              decoration: const InputDecoration(
                labelText: 'เบอร์โทรศัพท์',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (String? value) {
                final String text = (value ?? '').trim();
                if (text.isEmpty) return 'กรุณากรอกเบอร์โทรศัพท์';
                // นับเฉพาะตัวเลข เพราะขีดคั่นไม่ใช่ส่วนหนึ่งของหมายเลขจริง
                final int digits = text.replaceAll(RegExp(r'[^0-9]'), '').length;
                if (digits < 9) return 'เบอร์โทรต้องมีอย่างน้อย 9 หลัก';
                return null;
              },
            ),
            const SectionTitle(title: 'ช่วงวันเข้าพัก'),
            _DateRangeField(
              checkIn: _checkIn,
              checkOut: _checkOut,
              nights: nightsBetween(toIsoDate(_checkIn), toIsoDate(_checkOut)),
              onTap: _pickDateRange,
            ),
            const SizedBox(height: 8),
            Text(
              'เช็คอินตั้งแต่ ${ResortConfig.checkInTime} · '
              'เช็คเอาท์ก่อน ${ResortConfig.checkOutTime}',
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SectionTitle(title: 'ห้องพัก'),
            _buildRoomDropdown(),
            const SizedBox(height: 12),
            _GuestStepper(
              guests: _guests,
              maxGuests: _selectedRoom?.maxGuests,
              onChanged: (int value) => setState(() => _guests = value),
            ),
            const SizedBox(height: 12),
            _buildExtraBedTile(),
            const SectionTitle(title: 'รายละเอียดเพิ่มเติม'),
            TextFormField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'หมายเหตุ (ไม่บังคับ)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            _buildCheckInNowTile(),
            const SectionTitle(title: 'สรุปค่าใช้จ่าย'),
            _PriceSummary(breakdown: breakdown, room: _selectedRoom),
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_saving ? 'กำลังบันทึก...' : 'บันทึกรายการเข้าพัก'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ดรอปดาวน์เลือกห้อง แสดงเฉพาะห้องที่ว่างตลอดช่วงวันที่เลือกไว้
  Widget _buildRoomDropdown() {
    if (_loadingRooms) {
      return const AppCard(
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('กำลังตรวจสอบห้องว่าง...',
                style: TextStyle(color: AppColors.muted)),
          ],
        ),
      );
    }

    if (_availableRooms.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.occupiedBg,
          borderRadius: BorderRadius.circular(AppRadius.large),
          border: Border.all(color: AppColors.occupiedBorder, width: 0.5),
        ),
        child: const Row(
          children: <Widget>[
            Icon(Icons.error_outline, color: AppColors.occupied),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'ไม่มีห้องว่างในช่วงวันที่เลือก กรุณาเปลี่ยนวันเข้าพัก',
                style: TextStyle(color: AppColors.occupiedInk),
              ),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<Room>(
      initialValue: _selectedRoom,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'เลือกห้องพัก',
        prefixIcon: Icon(Icons.meeting_room_outlined),
      ),
      items: _availableRooms
          .map(
            (Room room) => DropdownMenuItem<Room>(
              value: room,
              child: Text(
                'ห้อง ${room.name} · ${room.type} · '
                '${formatBaht(room.price)}/คืน · สูงสุด ${room.maxGuests} ท่าน',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (Room? room) {
        setState(() {
          _selectedRoom = room;
          if (room != null && _guests > room.maxGuests) _guests = room.maxGuests;
        });
      },
      validator: (Room? room) => room == null ? 'กรุณาเลือกห้องพัก' : null,
    );
  }

  Widget _buildExtraBedTile() {
    return AppCard(
      padding: EdgeInsets.zero,
      child: CheckboxListTile(
        value: _extraBed,
        onChanged: (bool? value) => setState(() => _extraBed = value ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
        ),
        title: const Text(
          'ขอเตียงเสริม',
          style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink),
        ),
        subtitle: Text(
          '+${formatMoney(ResortConfig.extraBedFee)} บาท คิดครั้งเดียว',
          style: const TextStyle(color: AppColors.muted),
        ),
      ),
    );
  }

  Widget _buildCheckInNowTile() {
    return AppCard(
      padding: EdgeInsets.zero,
      child: SwitchListTile(
        value: _checkInNow,
        onChanged: (bool value) => setState(() => _checkInNow = value),
        activeThumbColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
        ),
        title: const Text(
          'เช็คอินทันที',
          style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink),
        ),
        subtitle: Text(
          _checkInNow
              ? 'แขกมาถึงแล้ว ห้องจะเปลี่ยนเป็นไม่ว่างทันที'
              : 'เป็นการจองล่วงหน้า ห้องยังว่างจนกว่าจะกดเช็คอิน',
          style: const TextStyle(color: AppColors.muted),
        ),
      ),
    );
  }
}

/// ช่องแสดงช่วงวันที่แบบสองกล่องคู่กัน แตะที่ไหนก็เปิดปฏิทินช่วงวันเดียวกัน
class _DateRangeField extends StatelessWidget {
  const _DateRangeField({
    required this.checkIn,
    required this.checkOut,
    required this.nights,
    required this.onTap,
  });

  final DateTime checkIn;
  final DateTime checkOut;
  final int nights;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.large),
      child: AppCard(
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                _DateBox(label: 'เช็คอิน', date: checkIn),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward, size: 18, color: AppColors.muted),
                ),
                _DateBox(label: 'เช็คเอาท์', date: checkOut),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(Icons.nights_stay_outlined, size: 16, color: AppColors.primaryDark),
                const SizedBox(width: 6),
                Text(
                  'รวม $nights คืน · แตะเพื่อเปลี่ยนวัน',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  const _DateBox({required this.label, required this.date});

  final String label;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(color: AppColors.line, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            const SizedBox(height: 2),
            Text(
              formatThaiDate(date),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ปุ่มลบและบวกจำนวนผู้เข้าพัก
/// ปิดปุ่มบวกเมื่อถึงความจุสูงสุดของห้อง เพื่อไม่ให้กรอกเกินแล้วค่อยไปเจอข้อความเตือนทีหลัง
class _GuestStepper extends StatelessWidget {
  const _GuestStepper({
    required this.guests,
    required this.maxGuests,
    required this.onChanged,
  });

  final int guests;

  /// ยังไม่เลือกห้องจะเป็น null ระหว่างนั้นจำกัดไว้ที่ค่าเผื่อไว้ก่อน
  final int? maxGuests;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final int limit = maxGuests ?? 4;
    final bool canAdd = guests < limit;
    final bool canRemove = guests > 1;

    return AppCard(
      child: Row(
        children: <Widget>[
          const Icon(Icons.people_outline, size: 20, color: AppColors.muted),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'จำนวนผู้เข้าพัก',
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink),
                ),
                Text(
                  maxGuests == null
                      ? 'เลือกห้องก่อนเพื่อดูความจุสูงสุด'
                      : 'ห้องนี้รับได้สูงสุด $limit ท่าน',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: canRemove ? () => onChanged(guests - 1) : null,
            icon: const Icon(Icons.remove_circle_outline),
            color: AppColors.primaryDark,
          ),
          Text(
            '$guests',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          IconButton(
            onPressed: canAdd ? () => onChanged(guests + 1) : null,
            icon: const Icon(Icons.add_circle_outline),
            color: AppColors.primaryDark,
          ),
        ],
      ),
    );
  }
}

/// กล่องสรุปค่าใช้จ่ายแบบแยกบรรทัด
///
/// จงใจไม่โชว์แค่ยอดเดียว เพราะพนักงานต้องอธิบายให้ลูกค้าฟังได้ว่าเงินแต่ละบาทมาจากไหน
/// บรรทัดค่าคนเพิ่มกับเตียงเสริมจะถูกซ่อนเมื่อไม่มีค่าใช้จ่ายส่วนนั้น เพื่อไม่ให้รกตา
class _PriceSummary extends StatelessWidget {
  const _PriceSummary({required this.breakdown, required this.room});

  final PriceBreakdown? breakdown;
  final Room? room;

  @override
  Widget build(BuildContext context) {
    final PriceBreakdown? data = breakdown;
    if (data == null || room == null) {
      return const AppCard(
        child: Row(
          children: <Widget>[
            Icon(Icons.calculate_outlined, color: AppColors.muted),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'เลือกห้องพักเพื่อคำนวณยอดเงิน',
                style: TextStyle(color: AppColors.muted),
              ),
            ),
          ],
        ),
      );
    }

    return AppCard(
      child: Column(
        children: <Widget>[
          _PriceRow(
            label: 'ค่าห้อง',
            detail: '${formatBaht(data.roomRate)} × ${data.nights} คืน',
            amount: data.roomTotal,
          ),
          if (data.extraGuests > 0)
            _PriceRow(
              label: 'ผู้เข้าพักคนที่ ${room!.baseGuests + 1}'
                  '${data.extraGuests > 1 ? '-${room!.baseGuests + data.extraGuests}' : ''}',
              detail: '${formatBaht(data.extraGuestFee)} × ${data.extraGuests} ท่าน '
                  '× ${data.nights} คืน',
              amount: data.extraGuestTotal,
            ),
          if (data.extraBed)
            _PriceRow(
              label: 'เตียงเสริม',
              detail: 'คิดครั้งเดียว ไม่คูณจำนวนคืน',
              amount: data.extraBedTotal,
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),
          Row(
            children: <Widget>[
              const Text(
                'รวมทั้งสิ้น',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const Spacer(),
              Text(
                formatBaht(data.total),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// หนึ่งบรรทัดในกล่องสรุปเงิน ประกอบด้วยชื่อรายการ วิธีคิด และจำนวนเงิน
class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.detail,
    required this.amount,
  });

  final String label;
  final String detail;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  detail,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          Text(
            formatMoney(amount),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
