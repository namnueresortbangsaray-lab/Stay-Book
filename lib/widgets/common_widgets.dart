// วิดเจ็ตชิ้นเล็ก ๆ ที่ถูกใช้ซ้ำในหลายหน้าจอ
// รวมไว้ที่เดียวเพื่อให้หน้าตาของหัวข้อ ป้ายสถานะ และการ์ดตัวเลขเหมือนกันทั้งแอป
import 'package:flutter/material.dart';

import '../config.dart';
import '../models/stay.dart';
import '../theme/app_theme.dart';

/// หัวข้อของแต่ละส่วนในหน้าจอ พร้อมข้อความเสริมด้านขวา เช่น "ว่าง 7 / 10"
class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
        ],
      ),
    );
  }
}

/// ป้ายสถานะของรายการเข้าพัก
///
/// จับคู่สีให้ตรงกับหน้าผังห้องโดยตั้งใจ คือสถานะ "เช็คอินแล้ว" ใช้โทนส้มเหมือน
/// การ์ดห้องไม่ว่าง ส่วน "เช็คเอาท์แล้ว" ใช้โทนเขียวเหมือนห้องว่าง
/// ผู้ใช้จึงเดาความหมายของสีได้โดยไม่ต้องอ่านข้อความ
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final int status;

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color background;
    late final Color foreground;
    late final Color border;

    switch (status) {
      case Stay.statusCheckedIn:
        label = 'เช็คอินแล้ว';
        background = AppColors.occupiedBg;
        foreground = AppColors.occupied;
        border = AppColors.occupiedBorder;
      case Stay.statusCheckedOut:
        label = 'เช็คเอาท์แล้ว';
        background = AppColors.vacantBg;
        foreground = AppColors.primaryDark;
        border = AppColors.vacantBorder;
      default:
        label = 'รอเช็คอิน';
        background = AppColors.surface;
        foreground = AppColors.muted;
        border = AppColors.line;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

/// การ์ดแสดงตัวเลขหนึ่งค่าในหน้าภาพรวม
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.accent = AppColors.primaryDark,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.line, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 13, color: AppColors.muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // ย่อขนาดตัวอักษรอัตโนมัติเมื่อยอดเงินยาวเกินความกว้างการ์ด
          // ดีกว่าปล่อยให้ข้อความล้นกรอบจนอ่านไม่ครบ
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// หน้าจอเปล่าเมื่อไม่มีข้อมูลให้แสดง บอกผู้ใช้ว่าไม่ใช่แอปค้าง แต่ยังไม่มีข้อมูลจริง ๆ
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.hint,
  });

  final IconData icon;
  final String title;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // วางไอคอนไว้ในวงกลมสีเขียวอ่อน ให้จอเปล่าดูเป็นส่วนหนึ่งของงานออกแบบ
            // ไม่ใช่ดูเหมือนหน้าจอที่โหลดไม่ขึ้น
            Container(
              width: 96,
              height: 96,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.vacantBg,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.vacantBorder, width: 0.5),
              ),
              child: Icon(icon, size: 44, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            if (hint != null) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                hint!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// กล่องพื้นขาวขอบบางที่ใช้เป็นฐานของการ์ดเกือบทุกใบในแอป
/// ใช้ขอบบาง 0.5 px แทนเงา เพราะเงาสีเทาบนพื้นหลังเขียวอ่อนจะทำให้ภาพรวมดูขุ่น
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.line, width: 0.5),
      ),
      child: child,
    );
  }
}

/// แสดงข้อความแจ้งผลการทำงาน ใช้แทนการเรียก ScaffoldMessenger ซ้ำ ๆ ทุกหน้า
/// [isError] ทำให้แถบเป็นสีส้มแดง ใช้กับกรณีบันทึกไม่สำเร็จ เช่น จองวันทับซ้อน
void showAppSnackBar(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.occupied : AppColors.ink,
        duration: const Duration(seconds: 3),
      ),
    );
}

/// ตราสัญลักษณ์ของรีสอร์ท
///
/// มีโลโก้สองเวอร์ชันเพราะไฟล์ต้นฉบับต่างกันคนละแบบ เวอร์ชันสีเขียวมองไม่เห็น
/// เมื่อวางบนพื้นเขียว ส่วนเวอร์ชันสีขาวก็หายไปกับพื้นขาว วิดเจ็ตนี้จึงเลือกไฟล์ให้ตาม
/// พื้นหลังที่จะไปวาง ผู้เรียกแค่บอกว่ากำลังวางบนพื้นสว่างหรือพื้นเขียวเข้ม
class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.size = 40,
    this.onLightBackground = true,
    this.framed = true,
    this.showWordmark = false,
  });

  /// สัดส่วนความสูงของไฟล์โลโก้ที่เป็นภาพบ้าน ต้นไม้ และดวงอาทิตย์
  /// ส่วนที่เหลือด้านล่างเป็นชื่อรีสอร์ทซึ่งเล็กเกินกว่าจะอ่านออกในขนาดไม่กี่สิบพิกเซล
  static const double _artworkHeightRatio = 0.68;

  final double size;

  /// true = วางบนพื้นสีอ่อน จะใช้โลโก้สีเขียว
  /// false = วางบนพื้นเขียวเข้ม จะใช้โลโก้สีขาว
  final bool onLightBackground;

  /// ใส่กรอบมุมมนรอบโลโก้หรือไม่
  final bool framed;

  /// แสดงชื่อรีสอร์ทที่อยู่ในไฟล์โลโก้ด้วยหรือไม่
  ///
  /// ค่าเริ่มต้นคือไม่แสดง เพราะทุกที่ที่ใช้ตรานี้มีชื่อรีสอร์ทเป็นตัวหนังสือกำกับอยู่แล้ว
  /// ถ้าโชว์ชื่อในโลโก้ด้วยจะกลายเป็นชื่อซ้ำสองชุด และตัวหนังสือในภาพก็เล็กจนอ่านไม่ออก
  final bool showWordmark;

  /// เลือกไฟล์โลโก้ให้เหมาะกับพื้นหลังและกับการแสดงชื่อ
  ///
  /// บนพื้นอ่อนที่ไม่ต้องโชว์ชื่อ ใช้ไฟล์พื้นโปร่งใสจะดีกว่า เพราะสีกรอบที่เลือกไว้
  /// จะทะลุมาเป็นพื้นของโลโก้พอดี ไม่เกิดสี่เหลี่ยมสีขาวซ้อนอยู่บนกรอบสีเขียวอ่อน
  /// ส่วนกรณีที่ต้องโชว์ชื่อ ต้องใช้ไฟล์จัตุรัสเพราะเป็นไฟล์เดียวที่คำว่า "บางเสร่" เป็นสีเข้ม
  String get _assetPath {
    if (!onLightBackground) return AppImages.logoWhite;
    return showWordmark ? AppImages.logoSquare : AppImages.logo;
  }

  @override
  Widget build(BuildContext context) {
    final double inner = framed ? size * 0.84 : size;

    // เมื่อไม่แสดงชื่อในโลโก้ ต้องทำให้ภาพสูงเกินกรอบก่อน แล้วค่อยครอบตัดส่วนล่างทิ้ง
    // ผลลัพธ์คือได้ภาพบ้านเต็มกรอบสี่เหลี่ยมจัตุรัสพอดี ไม่มีที่ว่างเหลือด้านล่าง
    final Widget picture = SizedBox(
      width: inner,
      height: showWordmark ? inner : inner / _artworkHeightRatio,
      child: Image.asset(
        _assetPath,
        fit: BoxFit.contain,
        // กันแอปพังทั้งจอถ้าไฟล์ภาพหาย ให้แสดงไอคอนบ้านแทนแล้วทำงานต่อได้
        errorBuilder: (BuildContext context, Object error, StackTrace? stack) => Icon(
          Icons.home_rounded,
          size: inner * 0.8,
          color: onLightBackground ? AppColors.primary : Colors.white,
        ),
      ),
    );

    final Widget logo = showWordmark
        ? picture
        : ClipRect(
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: _artworkHeightRatio,
              child: picture,
            ),
          );

    if (!framed) return logo;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        // บนพื้นเขียวใช้สีขาวโปร่งแสง เพื่อให้กรอบดูกลืนไปกับพื้นไล่เฉดข้างหลัง
        // ถ้าใช้ขาวทึบจะกลายเป็นแผ่นป้ายสว่างจ้าที่แย่งความสนใจจากข้อมูลจริง
        color: onLightBackground ? AppColors.vacantBg : Colors.white24,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(
          color: onLightBackground ? AppColors.vacantBorder : Colors.white38,
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.22),
        child: logo,
      ),
    );
  }
}
