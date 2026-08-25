// หน้าเปิดแอป แสดงโลโก้ของรีสอร์ทระหว่างที่ระบบเตรียมฐานข้อมูลให้พร้อม
//
// มีประโยชน์จริงสองข้อ ไม่ได้ใส่ไว้เพื่อความสวยอย่างเดียว
//   1. การเปิดไฟล์ฐานข้อมูลครั้งแรกต้องสร้างตารางและใส่ข้อมูลห้อง 15 ห้อง
//      ถ้าเข้าหน้าผังห้องเลย ผู้ใช้จะเห็นวงกลมหมุนบนจอเปล่า ๆ ซึ่งดูเหมือนแอปค้าง
//   2. เตรียมฐานข้อมูลไว้ล่วงหน้าตั้งแต่ตอนนี้ ทำให้หน้าแรกโหลดข้อมูลได้ทันที
import 'package:flutter/material.dart';

import '../config.dart';
import '../db/database_helper.dart';
import '../theme/app_theme.dart';
import 'home_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void initState() {
    super.initState();
    _boot();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// เตรียมฐานข้อมูลแล้วค่อยเข้าหน้าหลัก
  ///
  /// รอสองอย่างพร้อมกันด้วย Future.wait คือรอฐานข้อมูลพร้อม และรอเวลาขั้นต่ำ
  /// เพื่อไม่ให้หน้าโลโก้กะพริบผ่านไปเร็วจนอ่านไม่ทันในเครื่องที่เปิดเร็ว
  /// ผลคือใช้เวลาเท่ากับงานที่ช้ากว่า ไม่ใช่เอาสองเวลามาบวกกัน
  Future<void> _boot() async {
    await Future.wait(<Future<void>>[
      DatabaseHelper.instance.database.then((_) {}),
      Future<void>.delayed(const Duration(milliseconds: 1400)),
    ]);
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) => const HomeShell(),
        transitionsBuilder: (_, Animation<double> animation, __, Widget child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final CurvedAnimation curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: kBrandGradient),
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: curve,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.88, end: 1).animate(curve),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Image.asset(
                      AppImages.logoWhite,
                      width: 190,
                      height: 190,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.home_rounded,
                        size: 120,
                        color: Colors.white,
                      ),
                    ),
                    // ไม่เขียนชื่อรีสอร์ทซ้ำใต้โลโก้ เพราะในภาพโลโก้มีชื่อเต็มอยู่แล้ว
                    // และในขนาดใหญ่ระดับนี้อ่านออกชัดเจน การเขียนซ้ำจะกลายเป็นชื่อสองชุดซ้อนกัน
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 26),
                      child: Text(
                        ResortConfig.tagline,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    const SizedBox(height: 34),
                    const SizedBox(
                      width: 140,
                      child: ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        child: LinearProgressIndicator(
                          minHeight: 4,
                          backgroundColor: Colors.white24,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'กำลังเตรียมข้อมูลห้องพัก...',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
