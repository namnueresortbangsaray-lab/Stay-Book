import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stay_book/screens/guest_detail_screen.dart';
import 'package:stay_book/theme/app_theme.dart';
import 'package:stay_book/widgets/common_widgets.dart';

void main() {
  for (final width in <double>[320, 360, 400]) {
    for (final scale in <double>[1, 1.3, 2]) {
      testWidgets('Guest statistics fit at width $width and scale $scale', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(),
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: width,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: const <Widget>[
                        GuestStatistics(
                          children: <Widget>[
                            StatCard(
                              icon: Icons.hotel,
                              label: 'เข้าพักสำเร็จ',
                              value: '0 ครั้ง',
                            ),
                            StatCard(
                              icon: Icons.nights_stay,
                              label: 'คืนสะสม',
                              value: '0 คืน',
                            ),
                            StatCard(
                              icon: Icons.payments,
                              label: 'ยอดสะสม',
                              value: '฿1,234,567',
                            ),
                            StatCard(
                              icon: Icons.discount,
                              label: 'ส่วนลดสะสม',
                              value: '฿0',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(StatCard), findsNWidgets(4));
        expect(
          tester.getTopLeft(find.byType(StatCard).at(2)).dy,
          greaterThanOrEqualTo(
            tester.getBottomLeft(find.byType(StatCard).first).dy + 8,
          ),
        );
      });
    }
  }
}
