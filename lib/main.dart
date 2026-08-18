// จุดเริ่มต้นของแอป Stay Book
// หน้าที่ของไฟล์นี้มีอย่างเดียวคือประกอบธีมเข้ากับหน้าจอหลัก แล้วสั่งให้แอปทำงาน
import 'package:flutter/material.dart';

import 'config.dart';
import 'screens/home_shell.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const StayBookApp());
}

class StayBookApp extends StatelessWidget {
  const StayBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stay Book - ${ResortConfig.name}',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const HomeShell(),
    );
  }
}
