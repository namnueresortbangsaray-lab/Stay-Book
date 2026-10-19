// ฟอร์มสร้างหรือแก้ไข Booking พร้อมค้นหาลูกค้า ตรวจห้องว่าง และสรุปราคา
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config.dart';
import '../db/database_helper.dart';
import '../models/guest.dart';
import '../models/room.dart';
import '../models/stay.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';

class BookingFormScreen extends StatefulWidget {
  const BookingFormScreen({
    super.key,
    this.initialRoomId,
    this.initialGuest,
    this.existing,
  });
  final int? initialRoomId;
  final Guest? initialGuest;
  final StayWithRoom? existing;

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _note;
  late final TextEditingController _otherPetType;
  final _deposit = TextEditingController(text: '0');
  final _discount = TextEditingController(text: '0');
  late DateTime _checkIn;
  late DateTime _checkOut;
  List<Room> _rooms = <Room>[];
  Room? _room;
  Guest? _matchedGuest;
  int _guests = 1;
  bool _extraBed = false;
  bool _hasPet = false;
  String? _petType;
  int _petCount = 1;
  bool _depositPaid = false;
  bool _hasDiscount = false;
  bool _idVerified = false;
  bool _checkInNow = false;
  bool _loadingRooms = true;
  bool _saving = false;

  Stay? get _existing => widget.existing?.stay;

  @override
  void initState() {
    super.initState();
    final Stay? old = _existing;
    _name = TextEditingController(
      text: widget.initialGuest?.name ?? old?.guestName ?? '',
    );
    _phone = TextEditingController(
      text: widget.initialGuest?.phone ?? old?.phone ?? '',
    );
    _note = TextEditingController(text: old?.note ?? '');
    _checkIn = old == null
        ? dateOnly(DateTime.now())
        : parseIsoDate(old.checkInDate);
    _checkOut = old == null
        ? _checkIn.add(const Duration(days: 1))
        : parseIsoDate(old.checkOutDate);
    _guests = old?.guests ?? 1;
    _extraBed = old?.hasExtraBed ?? false;
    _hasPet = old?.hasPet ?? false;
    final String? savedPetType = old?.petType?.trim();
    final bool hasCustomPetType =
        savedPetType != null &&
        savedPetType.isNotEmpty &&
        !<String>{'สุนัข', 'แมว', 'อื่น ๆ'}.contains(savedPetType);
    _petType = hasCustomPetType ? 'อื่น ๆ' : savedPetType;
    _otherPetType = TextEditingController(
      text: hasCustomPetType ? savedPetType : '',
    );
    _petCount = old?.petCount ?? 1;
    _deposit.text = formatMoney(old?.depositAmount ?? 0).replaceAll(',', '');
    _discount.text = formatMoney(old?.discountAmount ?? 0).replaceAll(',', '');
    _depositPaid = old?.depositPaid ?? false;
    _hasDiscount = (old?.discountAmount ?? 0) > 0;
    _idVerified = old?.idVerified ?? false;
    _matchedGuest = widget.initialGuest;
    _loadRooms(preferred: widget.initialRoomId ?? old?.roomId);
    if (_phone.text.isNotEmpty && _matchedGuest == null) {
      _lookupGuest(_phone.text);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _note.dispose();
    _otherPetType.dispose();
    _deposit.dispose();
    _discount.dispose();
    super.dispose();
  }

  double _number(TextEditingController value) =>
      double.tryParse(value.text.replaceAll(',', '').trim()) ?? 0;
  PriceBreakdown? get _price => _room == null
      ? null
      : PriceBreakdown.calculate(
          room: _room!,
          guests: _guests,
          checkInDate: toIsoDate(_checkIn),
          checkOutDate: toIsoDate(_checkOut),
          extraBed: _extraBed,
          petCount: _hasPet ? _petCount : 0,
          discountAmount: _hasDiscount ? _number(_discount) : 0,
          depositAmount: _number(_deposit),
          depositPaid: _depositPaid,
        );

  Future<void> _loadRooms({int? preferred}) async {
    setState(() => _loadingRooms = true);
    final List<Room> rooms = await DatabaseHelper.instance.getRoomsForBooking(
      toIsoDate(_checkIn),
      toIsoDate(_checkOut),
      excludeStayId: _existing?.id,
      petFriendlyOnly: _hasPet,
    );
    if (!mounted) return;
    setState(() {
      _rooms = rooms;
      if (preferred != null) {
        for (final Room room in rooms) {
          if (room.id == preferred) _room = room;
        }
      }
      if (_room != null && !rooms.any((Room r) => r.id == _room!.id)) {
        _room = null;
      }
      _loadingRooms = false;
    });
  }

  Future<void> _lookupGuest(String value) async {
    final String normalized = normalizePhone(value);
    if (normalized.length < 9) {
      if (mounted) setState(() => _matchedGuest = null);
      return;
    }
    final Guest? guest = await DatabaseHelper.instance.findGuestByPhone(value);
    if (!mounted || normalizePhone(_phone.text) != normalized) return;
    setState(() => _matchedGuest = guest);
  }

  Future<void> _pickDates() async {
    final DateTimeRange? value = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 730)),
      lastDate: DateTime.now().add(const Duration(days: 1095)),
      initialDateRange: DateTimeRange(start: _checkIn, end: _checkOut),
      helpText: 'เลือกวันเช็กอินและเช็กเอาต์',
      cancelText: 'ยกเลิก',
      confirmText: 'ตกลง',
    );
    if (value == null) return;
    setState(() {
      _checkIn = dateOnly(value.start);
      _checkOut = dateOnly(value.end).isAfter(_checkIn)
          ? dateOnly(value.end)
          : _checkIn.add(const Duration(days: 1));
    });
    await _loadRooms(preferred: _room?.id);
  }

  void _togglePet(bool value) {
    final bool clearRoom = value && _room != null && !_room!.isPetFriendly;
    setState(() {
      _hasPet = value;
      if (!value) {
        _petType = null;
        _otherPetType.clear();
        _petCount = 1;
      }
      if (clearRoom) _room = null;
    });
    if (clearRoom) {
      showAppSnackBar(
        context,
        'ห้องเดิมไม่รองรับสัตว์เลี้ยง กรุณาเลือกห้องใหม่',
        isError: true,
      );
    }
    _loadRooms(preferred: _room?.id);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _room == null) return;
    if (!_checkOut.isAfter(_checkIn)) {
      showAppSnackBar(
        context,
        'วันเช็กเอาต์ต้องอยู่หลังวันเช็กอิน',
        isError: true,
      );
      return;
    }
    final PriceBreakdown price = _price!;
    if (_hasPet &&
        (_petType == null || _petCount < 1 || !_room!.isPetFriendly)) {
      showAppSnackBar(
        context,
        'กรุณาเลือกประเภท จำนวน และห้องที่รองรับสัตว์เลี้ยง',
        isError: true,
      );
      return;
    }
    if (_hasPet && _petType == 'อื่น ๆ' && _otherPetType.text.trim().isEmpty) {
      showAppSnackBar(
        context,
        'กรุณาระบุว่าสัตว์เลี้ยงเป็นสัตว์อะไร',
        isError: true,
      );
      return;
    }
    if (_hasDiscount &&
        (_number(_discount) <= 0 || _number(_discount) > price.grossTotal)) {
      showAppSnackBar(
        context,
        'ส่วนลดต้องมากกว่า 0 และไม่เกินราคาก่อนส่วนลด',
        isError: true,
      );
      return;
    }
    if (_number(_deposit) < 0 || _number(_deposit) > price.total) {
      showAppSnackBar(
        context,
        'เงินมัดจำต้องอยู่ระหว่าง 0 ถึงยอดสุทธิ',
        isError: true,
      );
      return;
    }
    if (_checkInNow && !_idVerified) {
      showAppSnackBar(
        context,
        'ต้องตรวจสอบบัตรประชาชนก่อนเช็กอินทันที',
        isError: true,
      );
      return;
    }
    if (await DatabaseHelper.instance.hasOverlap(
      _room!.id!,
      toIsoDate(_checkIn),
      toIsoDate(_checkOut),
      excludeStayId: _existing?.id,
    )) {
      if (mounted) {
        showAppSnackBar(
          context,
          'ห้องนี้มี Booking ทับช่วงวันที่เลือก',
          isError: true,
        );
      }
      return;
    }
    setState(() => _saving = true);
    final double deposit = _number(_deposit);
    final Stay stay = Stay(
      id: _existing?.id,
      guestId: _matchedGuest?.id ?? _existing?.guestId,
      guestName: _name.text.trim(),
      phone: _phone.text.trim(),
      roomId: _room!.id!,
      checkInDate: toIsoDate(_checkIn),
      checkOutDate: toIsoDate(_checkOut),
      guests: _guests,
      extraBed: _extraBed ? 1 : 0,
      totalAmount: price.total,
      status:
          _existing?.status ??
          (_checkInNow ? Stay.statusCheckedIn : Stay.statusBooked),
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      createdAt: _existing?.createdAt ?? DateTime.now().toIso8601String(),
      depositAmount: deposit,
      depositPaid: deposit > 0 && _depositPaid,
      idVerified: _idVerified,
      petType: _hasPet
          ? (_petType == 'อื่น ๆ' ? _otherPetType.text.trim() : _petType)
          : null,
      petCount: _hasPet ? _petCount : 0,
      petFee: price.petTotal,
      discountAmount: _hasDiscount ? _number(_discount) : 0,
    );
    try {
      if (_existing == null) {
        await DatabaseHelper.instance.createStayWithGuest(stay);
      } else {
        await DatabaseHelper.instance.updateStay(stay);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        showAppSnackBar(context, error.toString(), isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_existing == null ? 'เปิดรายการเข้าพัก' : 'แก้ไข Booking'),
    ),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        children: <Widget>[
          const SectionTitle(title: 'ข้อมูลผู้เข้าพัก'),
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'ชื่อผู้เข้าพัก'),
            validator: (v) => (v ?? '').trim().length < 2
                ? 'กรุณากรอกชื่ออย่างน้อย 2 ตัวอักษร'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[0-9 -]')),
            ],
            onChanged: _lookupGuest,
            decoration: const InputDecoration(labelText: 'เบอร์โทรศัพท์'),
            validator: (v) => normalizePhone(v ?? '').length < 9
                ? 'กรุณากรอกตัวเลขอย่างน้อย 9 หลัก'
                : null,
          ),
          if (_matchedGuest != null) _guestMatch(),
          const SectionTitle(title: 'ช่วงวันและห้องพัก'),
          AppCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              onTap: _pickDates,
              leading: const Icon(Icons.date_range, color: AppColors.primary),
              title: Text(
                '${formatThaiDate(_checkIn)} – ${formatThaiDate(_checkOut)}',
              ),
              subtitle: Text(
                '${nightsBetween(toIsoDate(_checkIn), toIsoDate(_checkOut))} คืน · เช็กอิน ${ResortConfig.checkInTime}',
              ),
              trailing: const Icon(Icons.edit_calendar_outlined),
            ),
          ),
          const SizedBox(height: 12),
          if (_loadingRooms)
            const Center(child: CircularProgressIndicator())
          else
            DropdownButtonFormField<Room>(
              initialValue: _room,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'ห้องพัก'),
              items: _rooms
                  .map(
                    (r) => DropdownMenuItem(
                      value: r,
                      child: Text(
                        'ห้อง ${r.name} · ${formatBaht(r.price)}${r.isPetFriendly ? ' · Pet Friendly' : ''}',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (r) => setState(() {
                _room = r;
                if (r != null && _guests > r.maxGuests) _guests = r.maxGuests;
              }),
              validator: (r) => r == null ? 'กรุณาเลือกห้องพัก' : null,
            ),
          const SizedBox(height: 12),
          _stepper(
            'จำนวนผู้เข้าพัก',
            _guests,
            1,
            _room?.maxGuests ?? 1,
            (v) => setState(() => _guests = v),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _extraBed,
            onChanged: (v) => setState(() => _extraBed = v ?? false),
            title: const Text('ขอเตียงเสริม'),
            subtitle: Text(
              '${formatBaht(ResortConfig.extraBedFee)} คิดครั้งเดียว',
            ),
          ),
          const SectionTitle(title: 'สัตว์เลี้ยงและค่าใช้จ่าย'),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _hasPet,
            onChanged: (v) => _togglePet(v ?? false),
            title: const Text('นำสัตว์เลี้ยงเข้าพัก'),
            subtitle: Text(
              '${formatBaht(ResortConfig.petFeePerNight)} ต่อห้องต่อคืน',
            ),
          ),
          if (_hasPet) ...<Widget>[
            DropdownButtonFormField<String>(
              initialValue: _petType,
              decoration: const InputDecoration(labelText: 'ประเภทสัตว์เลี้ยง'),
              items: <String>[
                'สุนัข',
                'แมว',
                'อื่น ๆ',
              ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) => setState(() {
                _petType = v;
                if (v != 'อื่น ๆ') _otherPetType.clear();
              }),
              validator: (v) =>
                  v == null ? 'กรุณาเลือกประเภทสัตว์เลี้ยง' : null,
            ),
            if (_petType == 'อื่น ๆ') ...<Widget>[
              const SizedBox(height: 12),
              TextFormField(
                controller: _otherPetType,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'ระบุว่าสัตว์อะไร',
                  hintText: 'เช่น กระต่าย นก หรือหนูแฮมสเตอร์',
                  prefixIcon: Icon(Icons.edit_note_outlined),
                ),
                validator: (v) =>
                    _hasPet && _petType == 'อื่น ๆ' && (v ?? '').trim().isEmpty
                    ? 'กรุณาระบุชนิดสัตว์เลี้ยง'
                    : null,
              ),
            ],
            const SizedBox(height: 12),
            _stepper(
              'จำนวนสัตว์เลี้ยง',
              _petCount,
              1,
              10,
              (v) => setState(() => _petCount = v),
            ),
          ],
          TextFormField(
            controller: _deposit,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'เงินมัดจำ (บาท)'),
            onChanged: (_) => setState(() {}),
            validator: (v) =>
                _number(_deposit) < 0 ? 'เงินมัดจำห้ามติดลบ' : null,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _depositPaid && _number(_deposit) > 0,
            onChanged: _number(_deposit) > 0
                ? (v) => setState(() => _depositPaid = v)
                : null,
            title: const Text('ได้รับเงินมัดจำแล้ว'),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _hasDiscount,
            onChanged: (v) => setState(() {
              _hasDiscount = v ?? false;
              if (!_hasDiscount) _discount.text = '0';
            }),
            title: const Text('ให้ส่วนลดแก่ลูกค้า'),
          ),
          if (_hasDiscount)
            TextFormField(
              controller: _discount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'ส่วนลด (บาท)'),
              onChanged: (_) => setState(() {}),
            ),
          const SectionTitle(title: 'การยืนยันและหมายเหตุ'),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _idVerified,
            onChanged: (v) => setState(() => _idVerified = v ?? false),
            title: const Text('ตรวจสอบบัตรประชาชนแล้ว'),
            subtitle: const Text('ระบบเก็บเฉพาะสถานะ ไม่เก็บเลขบัตร'),
          ),
          TextFormField(
            controller: _note,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'หมายเหตุเฉพาะ Booking',
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _checkInNow,
            onChanged: _existing == null
                ? (v) => setState(() => _checkInNow = v)
                : null,
            title: const Text('เช็กอินทันที'),
            subtitle: const Text('ต้องตรวจสอบบัตรแล้ว'),
          ),
          const SectionTitle(title: 'สรุปค่าใช้จ่าย'),
          _priceSummary(),
        ],
      ),
    ),
    bottomNavigationBar: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: const Icon(Icons.save_outlined),
          label: Text(_saving ? 'กำลังบันทึก...' : 'บันทึก Booking'),
        ),
      ),
    ),
  );

  Widget _guestMatch() => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.successBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.person_search, color: AppColors.success),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'พบ ${_matchedGuest!.name} · ${_matchedGuest!.customerType}${_matchedGuest!.isRegular ? ' · ลูกค้าประจำ' : ''}',
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _name.text = _matchedGuest!.name),
            child: const Text('ใช้ข้อมูล'),
          ),
        ],
      ),
    ),
  );

  Widget _stepper(
    String label,
    int value,
    int min,
    int max,
    ValueChanged<int> changed,
  ) => AppCard(
    child: Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(
          onPressed: value > min ? () => changed(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text(
          '$value',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        IconButton(
          onPressed: value < max ? () => changed(value + 1) : null,
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    ),
  );

  Widget _priceSummary() {
    final PriceBreakdown? p = _price;
    if (p == null) return const AppCard(child: Text('เลือกห้องเพื่อคำนวณราคา'));
    return AppCard(
      child: Column(
        children: <Widget>[
          _moneyRow(
            'ค่าห้อง',
            '${formatBaht(p.roomRate)} × ${p.nights} คืน',
            p.roomTotal,
          ),
          if (p.extraGuests > 0)
            _moneyRow(
              'ผู้เข้าพักเพิ่ม',
              '${p.extraGuests} คน × ${p.nights} คืน',
              p.extraGuestTotal,
            ),
          if (p.petTotal > 0)
            _moneyRow(
              'สัตว์เลี้ยง',
              '${formatBaht(p.petFeePerNight)} × ${p.nights} คืน',
              p.petTotal,
            ),
          if (p.extraBedTotal > 0)
            _moneyRow('เตียงเสริม', 'คิดครั้งเดียว', p.extraBedTotal),
          const Divider(),
          _moneyRow('ราคาก่อนส่วนลด', '', p.grossTotal, bold: true),
          if (p.discountAmount > 0) _moneyRow('ส่วนลด', '', -p.discountAmount),
          _moneyRow('ยอดสุทธิ', '', p.total, bold: true),
          if (p.paidDeposit > 0)
            _moneyRow('มัดจำที่ชำระแล้ว', '', -p.paidDeposit),
          const Divider(),
          _moneyRow('ยอดคงเหลือ', '', p.balanceDue, bold: true),
        ],
      ),
    );
  }

  Widget _moneyRow(
    String label,
    String detail,
    double amount, {
    bool bold = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
        if (detail.isNotEmpty)
          Flexible(
            child: Text(
              detail,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ),
        const SizedBox(width: 8),
        Text(
          formatBaht(amount),
          style: TextStyle(
            fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
            color: bold ? AppColors.primaryDark : AppColors.ink,
          ),
        ),
      ],
    ),
  );
}
