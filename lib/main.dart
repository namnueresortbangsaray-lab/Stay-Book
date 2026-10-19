// จุดเริ่มต้นของแอป Stay Book ของน้ำเหนือรีสอร์ทบางเสร่
// หน้าที่ของไฟล์นี้มีอย่างเดียวคือประกอบธีมเข้ากับหน้าจอแรก แล้วสั่งให้แอปทำงาน
import 'package:flutter/material.dart';

import 'config.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const StayBookApp());
}

class StayBookApp extends StatelessWidget {
  const StayBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: ResortConfig.name,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      // เริ่มที่หน้าโลโก้ก่อน เพื่อเตรียมฐานข้อมูลให้เสร็จก่อนเข้าหน้าผังห้อง
      home: const SplashScreen(),
    );
  }
}
