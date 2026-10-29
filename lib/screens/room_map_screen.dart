// หน้าผังห้องพัก เป็นหน้าแรกที่พนักงานเห็น ตอบคำถามว่า "ตอนนี้ห้องไหนว่างบ้าง"
// ได้ภายในไม่กี่วินาที โดยไม่ต้องกดอะไรเพิ่ม
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../config.dart';
import '../db/database_helper.dart';
import '../models/room.dart';
import '../models/stay.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';
import '../widgets/room_tile.dart';
import 'booking_form_screen.dart';

class RoomMapScreen extends StatelessWidget {
  const RoomMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilder ฟังสัญญาณว่าฐานข้อมูลเปลี่ยน เมื่อค่าขยับจะ build ใหม่
    // ทำให้ FutureBuilder ข้างในได้ Future ตัวใหม่ และไปดึงข้อมูลรอบใหม่ให้เอง
    return ValueListenableBuilder<int>(
      valueListenable: dbRevision,
      builder: (BuildContext context, int revision, Widget? child) {
        return FutureBuilder<List<RoomWithStay>>(
          future: DatabaseHelper.instance.getRoomsWithCurrentStay(),
          builder: (
            BuildContext context,
            AsyncSnapshot<List<RoomWithStay>> snapshot,
          ) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final List<RoomWithStay> rooms = snapshot.data ?? <RoomWithStay>[];
            if (rooms.isEmpty) {
              return const EmptyState(
                icon: Icons.meeting_room_outlined,
                title: 'ยังไม่มีห้องพักในระบบ',
                hint: 'ไปที่แท็บห้องพักเพื่อเพิ่มห้องแรก',
              );
            }
            return _RoomMapBody(rooms: rooms);
          },
        );
      },
    );
  }
}

class _RoomMapBody extends StatelessWidget {
  const _RoomMapBody({required this.rooms});

  final List<RoomWithStay> rooms;

  /// จัดกลุ่มห้องตามโซน โดยยังรักษาลำดับตาม sort_order ที่คิวรีเรียงมาให้แล้ว
  /// ใช้ Map ธรรมดาของ Dart ซึ่งจำลำดับการใส่คีย์ตามที่ใส่เข้าไปจริง
  Map<String, List<RoomWithStay>> _groupByZone() {
    final Map<String, List<RoomWithStay>> grouped = <String, List<RoomWithStay>>{};
    for (final RoomWithStay item in rooms) {
      grouped.putIfAbsent(item.room.zone, () => <RoomWithStay>[]).add(item);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final int occupiedCount = rooms.where((RoomWithStay r) => r.isOccupied).length;
    final int vacantCount = rooms.length - occupiedCount;
    final Map<String, List<RoomWithStay>> grouped = _groupByZone();

    // ใช้ ListView ตัวเดียวเป็นตัวเลื่อนหน้าจอ แล้วให้ GridView ของแต่ละโซนอยู่ข้างใน
    // แบบไม่เลื่อนเอง (NeverScrollableScrollPhysics) ไม่งั้นจะมีตัวเลื่อนซ้อนกันหลายชั้น
    // และ Flutter จะไม่รู้ว่าต้องให้ความสูงเท่าไรกับ GridView ที่อยู่ใน ListView
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 96),
      children: <Widget>[
        _SummaryBar(vacant: vacantCount, occupied: occupiedCount, total: rooms.length),
        for (final MapEntry<String, List<RoomWithStay>> entry in grouped.entries) ...<Widget>[
          SectionTitle(
            title: entry.key,
            trailing: 'ว่าง '
                '${entry.value.where((RoomWithStay r) => !r.isOccupied).length}'
                ' / ${entry.value.length}',
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: entry.value.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.92,
            ),
            itemBuilder: (BuildContext context, int index) {
              final RoomWithStay item = entry.value[index];
              return RoomTile(
                data: item,
                onTap: () => _onTapRoom(context, item),
              );
            },
          ),
        ],
      ],
    );
  }

  /// ห้องว่างเปิดฟอร์มจองโดยเลือกห้องนั้นไว้ให้เลย ส่วนห้องไม่ว่างเปิดข้อมูลแขก
  /// ออกแบบให้การแตะการ์ดพาไปยังงานที่พนักงานน่าจะอยากทำต่อมากที่สุดในสถานะนั้น
  Future<void> _onTapRoom(BuildContext context, RoomWithStay item) async {
    if (item.isOccupied) {
      await _showOccupiedSheet(context, item);
      return;
    }

    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => BookingFormScreen(initialRoomId: item.room.id),
      ),
    );
    if (saved == true && context.mounted) {
      showAppSnackBar(context, 'บันทึกรายการเข้าพักเรียบร้อย');
    }
  }

  /// แผ่นข้อมูลด้านล่างสำหรับห้องที่มีแขกอยู่
  /// ดึงข้อมูลรายการเข้าพักฉบับเต็มอีกครั้ง เพราะคิวรีของหน้าผังห้องเอามาเฉพาะ
  /// ฟิลด์ที่ต้องใช้วาดการ์ด ไม่ได้เอาเบอร์โทรกับยอดเงินมาด้วย
  Future<void> _showOccupiedSheet(BuildContext context, RoomWithStay item) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetContext) {
        return FutureBuilder<StayWithRoom?>(
          future: DatabaseHelper.instance.getActiveStayOfRoom(item.room.id!),
          builder: (BuildContext context, AsyncSnapshot<StayWithRoom?> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 220,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final StayWithRoom? data = snapshot.data;
            if (data == null) {
              return const SizedBox(
                height: 220,
                child: EmptyState(
                  icon: Icons.info_outline,
                  title: 'ไม่พบข้อมูลผู้เข้าพักของห้องนี้',
                ),
              );
            }
            return _OccupiedSheet(data: data);
          },
        );
      },
    );
  }
}

/// การ์ดหัวหน้าผังห้อง รวมตราสัญลักษณ์ วันที่วันนี้ และสรุปจำนวนห้องไว้ใบเดียว
///
/// ใช้พื้นเขียวไล่เฉดให้ต่างจากการ์ดขาวใบอื่นในหน้า เพราะเป็นข้อมูลสรุปภาพรวม
/// ไม่ใช่รายการที่กดเข้าไปดูรายละเอียดได้ ความต่างของพื้นช่วยบอกบทบาทนี้โดยไม่ต้องเขียนอธิบาย
class _SummaryBar extends StatelessWidget {
  const _SummaryBar({
    required this.vacant,
    required this.occupied,
    required this.total,
  });

  final int vacant;
  final int occupied;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: kBrandGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const BrandMark(size: 44, onLightBackground: false),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      ResortConfig.shortName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatThaiDateFull(DateTime.now()),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              _CountPill(
                color: AppColors.primaryDark,
                label: 'ว่าง',
                count: vacant,
              ),
              const SizedBox(width: 10),
              _CountPill(
                color: AppColors.occupied,
                label: 'ไม่ว่าง',
                count: occupied,
              ),
              // ใช้ Expanded แทน Spacer เพื่อให้ข้อความหดตัวได้เมื่อจอแคบหรือผู้ใช้
              // ตั้งขนาดตัวอักษรของเครื่องไว้ใหญ่ ดีกว่าปล่อยให้ล้นขอบการ์ด
              Expanded(
                child: Text(
                  'รวม $total ห้อง',
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ป้ายตัวเลขทรงแคปซูลบนพื้นเขียว ใช้บอกจำนวนห้องว่างและไม่ว่าง
class _CountPill extends StatelessWidget {
  const _CountPill({
    required this.color,
    required this.label,
    required this.count,
  });

  final Color color;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            '$label $count',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// เนื้อหาของแผ่นข้อมูลผู้เข้าพัก พร้อมปุ่มเช็คเอาท์
class _OccupiedSheet extends StatelessWidget {
  const _OccupiedSheet({required this.data});

  final StayWithRoom data;

  Future<void> _checkOut(BuildContext context) async {
    // เก็บ Navigator กับ ScaffoldMessenger ไว้ก่อนเรียกงานที่ต้องรอ
    // เพราะหลัง await แผ่นนี้กำลังจะถูกปิด การไปหยิบจาก context ตอนนั้นไม่ปลอดภัย
    final NavigatorState navigator = Navigator.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    await DatabaseHelper.instance.checkOut(data.stay.id!);
    navigator.pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('เช็คเอาท์ห้อง ${data.roomName} เรียบร้อย ห้องกลับมาว่างแล้ว'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final Stay stay = data.stay;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Text(
                'ห้อง ${data.roomName}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(width: 10),
              StatusChip(status: stay.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            data.zone,
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          _SheetRow(icon: Icons.person_outline, label: 'ผู้เข้าพัก', value: stay.guestName),
          _SheetRow(
            icon: Icons.phone_outlined,
            label: 'เบอร์โทร',
            value: (stay.phone == null || stay.phone!.isEmpty) ? '-' : stay.phone!,
          ),
          _SheetRow(
            icon: Icons.login,
            label: 'เช็คอิน',
            value: '${formatIsoAsThaiDate(stay.checkInDate)} '
                '(ตั้งแต่ ${ResortConfig.checkInTime})',
          ),
          _SheetRow(
            icon: Icons.logout,
            label: 'เช็คเอาท์',
            value: '${formatIsoAsThaiDate(stay.checkOutDate)} '
                '(ก่อน ${ResortConfig.checkOutTime})',
          ),
          _SheetRow(
            icon: Icons.people_outline,
            label: 'ผู้เข้าพัก',
            value: '${stay.guests} ท่าน · ${stay.nights} คืน'
                '${stay.hasExtraBed ? ' · มีเตียงเสริม' : ''}',
          ),
          if (stay.note != null && stay.note!.isNotEmpty)
            _SheetRow(icon: Icons.sticky_note_2_outlined, label: 'หมายเหตุ', value: stay.note!),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              const Text(
                'ยอดรวมทั้งสิ้น',
                style: TextStyle(fontSize: 15, color: AppColors.muted),
              ),
              const Spacer(),
              Text(
                formatBaht(stay.totalAmount),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _checkOut(context),
              icon: const Icon(Icons.logout),
              label: const Text('เช็คเอาท์ห้องนี้'),
            ),
          ),
        ],
      ),
    );
  }
}

/// หนึ่งบรรทัดข้อมูลในแผ่นด้านล่าง จัดวางไอคอน หัวข้อ และค่าให้ตรงแนวกันทุกบรรทัด
class _SheetRow extends StatelessWidget {
  const _SheetRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: AppColors.muted),
          const SizedBox(width: 10),
          SizedBox(
            width: 78,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
