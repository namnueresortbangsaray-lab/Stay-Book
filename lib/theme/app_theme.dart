// ศูนย์รวมสีและรูปแบบหน้าตาของแอปทั้งหมด
// ทุกหน้าจอต้องอ้างสีจาก AppColors เท่านั้น ห้ามเขียนค่าสีดิบกระจายในไฟล์หน้าจอ
// เพราะถ้าอยากเปลี่ยนโทนสีทั้งแอปจะได้แก้จุดเดียวจบ
import 'package:flutter/material.dart';

/// ชุดสีของธีม "เขียวสว่างสดใส"
class AppColors {
  const AppColors._();

  /// สีหลักของแบรนด์ ใช้กับ AppBar ปุ่มหลัก และไอคอนที่ถูกเลือก
  static const Color primary = Color(0xFF1FA84C);

  /// เขียวเข้ม ใช้เน้นตัวเลขยอดเงินให้อ่านชัดบนพื้นขาว
  static const Color primaryDark = Color(0xFF147A37);

  /// สีตัวอักษรหลัก เป็นเขียวอมดำเพื่อให้กลมกลืนกับธีมมากกว่าสีดำล้วน
  static const Color ink = Color(0xFF0E3D1E);

  /// สีตัวอักษรรอง ใช้กับคำอธิบายที่ไม่ต้องเด่นเท่าหัวข้อ
  static const Color muted = Color(0xFF4A8A5B);

  /// พื้นหลังของทุกหน้าจอ เขียวอ่อนมากเพื่อให้การ์ดสีขาวลอยขึ้นมา
  static const Color bg = Color(0xFFF2FBF3);

  /// พื้นการ์ดทั่วไป
  static const Color surface = Color(0xFFFFFFFF);

  /// พื้นและขอบของการ์ดห้องว่าง
  static const Color vacantBg = Color(0xFFE4F7E8);
  static const Color vacantBorder = Color(0xFF7ACF90);

  /// สีส้มอิฐสำหรับสถานะ "ไม่ว่าง" เลือกสีตรงข้ามกับเขียวเพื่อให้แยกออกทันทีที่มอง
  static const Color occupied = Color(0xFFD85A30);
  static const Color occupiedBg = Color(0xFFFAECE7);
  static const Color occupiedBorder = Color(0xFFE08765);

  /// ตัวอักษรบนการ์ดห้องไม่ว่าง ต้องเป็นโทนน้ำตาลเข้มจึงจะอ่านชัดบนพื้นส้มอ่อน
  static const Color occupiedInk = Color(0xFF4A1B0C);
  static const Color occupiedMuted = Color(0xFF993C1D);

  /// เส้นขอบและเส้นคั่นทั่วไป
  static const Color line = Color(0xFFC9E7CF);

  // สองสีด้านล่างดูดมาจากภาพโลโก้โดยตรง เพื่อให้สีในแอปกับสีบนป้ายของรีสอร์ท
  // เป็นชุดเดียวกัน ใช้เป็นสีเสริมเท่านั้น ไม่ใช้แทนสีหลัก

  /// เขียวใบไม้อ่อนจากตัวบ้านในโลโก้ ใช้ไล่เฉดบนแถบหัวเรื่อง
  static const Color leaf = Color(0xFF95D3A0);

  /// เหลืองดวงอาทิตย์จากโลโก้ ใช้เน้นจุดเล็ก ๆ ที่ต้องการให้สะดุดตา
  static const Color sun = Color(0xFFF5E27A);
}

/// ไล่เฉดสีเขียวของแบรนด์ ใช้กับแถบหัวเรื่องและการ์ดหัวหน้าผังห้อง
/// แยกออกมาเป็นค่าคงที่เพื่อให้ทุกที่ที่ใช้พื้นเขียวไล่เฉดได้ทิศทางและสีเดียวกัน
const LinearGradient kBrandGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: <Color>[AppColors.primary, AppColors.primaryDark],
);

/// ค่ามุมโค้งมาตรฐานของแอป การ์ดทุกใบใช้ค่าจากตรงนี้เพื่อให้หน้าตาสม่ำเสมอ
class AppRadius {
  const AppRadius._();
  static const double small = 11;
  static const double medium = 12;
  static const double large = 14;
}

/// สร้าง ThemeData ของแอป เรียกครั้งเดียวจาก main.dart
///
/// ตั้งใจไม่ใส่เงาให้การ์ด แต่ใช้ขอบบาง 0.5 px แทน เพราะพื้นหลังเป็นเขียวอ่อน
/// เงาสีเทาจะทำให้ดูขุ่น ส่วนขอบบางให้ความรู้สึกสะอาดกว่า
ThemeData buildAppTheme() {
  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    surface: AppColors.surface,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 19,
        fontWeight: FontWeight.w700,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.vacantBg,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
      labelStyle: const TextStyle(color: AppColors.muted),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryDark,
        side: const BorderSide(color: AppColors.vacantBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.primaryDark),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
    ),
    dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      contentTextStyle: TextStyle(color: Colors.white),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700),
      titleMedium: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700),
      bodyMedium: TextStyle(color: AppColors.ink),
      bodySmall: TextStyle(color: AppColors.muted),
    ),
  );
}
