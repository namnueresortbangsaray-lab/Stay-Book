// โครงหลักของแอป ประกอบด้วยแถบหัวเรื่อง แถบเมนูล่าง 4 แท็บ และปุ่มลอยเปิดรายการเข้าพัก
// ทุกหน้าจอหลักถูกวางไว้ใน IndexedStack เพื่อให้สลับแท็บแล้วสถานะของแต่ละหน้ายังอยู่ครบ
// เช่น วันที่ที่เลือกไว้ในหน้าตารางเข้าพัก จะไม่ถูกรีเซ็ตเมื่อสลับไปดูหน้าอื่นแล้วกลับมา
import 'package:flutter/material.dart';

import '../config.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'booking_form_screen.dart';
import 'dashboard_screen.dart';
import 'manage_rooms_screen.dart';
import 'room_map_screen.dart';
import 'stay_list_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  /// ชื่อแท็บใช้ทั้งในแถบเมนูล่างและเป็นบรรทัดรองบนแถบหัวเรื่อง
  static const List<String> _titles = <String>[
    'ผังห้องพัก',
    'ตารางเข้าพัก',
    'ภาพรวม',
    'ห้องพัก',
  ];

  /// เปิดฟอร์มเปิดรายการเข้าพัก แล้วแจ้งผลเมื่อบันทึกสำเร็จ
  /// ฟอร์มคืนค่า true กลับมาเมื่อบันทึกเรียบร้อย จึงใช้ค่านั้นตัดสินใจว่าจะขึ้นข้อความหรือไม่
  Future<void> _openBookingForm() async {
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const BookingFormScreen()),
    );
    if (saved == true && mounted) {
      showAppSnackBar(context, 'บันทึกรายการเข้าพักเรียบร้อย');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(ResortConfig.name),
            Text(
              _titles[_currentIndex],
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const <Widget>[
          RoomMapScreen(),
          StayListScreen(),
          DashboardScreen(),
          ManageRoomsScreen(),
        ],
      ),
      // ซ่อนปุ่มลอยในแท็บจัดการห้องพัก เพราะหน้านั้นมีปุ่มเพิ่มห้องเป็นของตัวเองอยู่แล้ว
      // ถ้าแสดงทั้งสองปุ่มพร้อมกันจะทับกันและทำให้ผู้ใช้สับสนว่าปุ่มไหนทำอะไร
      floatingActionButton: _currentIndex == 3
          ? null
          : FloatingActionButton.extended(
              onPressed: _openBookingForm,
              icon: const Icon(Icons.add),
              label: const Text('เปิดรายการเข้าพัก'),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) =>
            setState(() => _currentIndex = index),
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined, color: AppColors.muted),
            selectedIcon: Icon(Icons.grid_view_rounded, color: AppColors.primaryDark),
            label: 'ผังห้อง',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined, color: AppColors.muted),
            selectedIcon: Icon(Icons.list_alt, color: AppColors.primaryDark),
            label: 'ตารางเข้าพัก',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined, color: AppColors.muted),
            selectedIcon: Icon(Icons.insights, color: AppColors.primaryDark),
            label: 'ภาพรวม',
          ),
          NavigationDestination(
            icon: Icon(Icons.meeting_room_outlined, color: AppColors.muted),
            selectedIcon: Icon(Icons.meeting_room, color: AppColors.primaryDark),
            label: 'ห้องพัก',
          ),
        ],
      ),
    );
  }
}
