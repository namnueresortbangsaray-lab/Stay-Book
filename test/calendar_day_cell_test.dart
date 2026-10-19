// ป้องกัน regression ของ RenderFlex overflow ในช่องปฏิทินขนาดเล็ก
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stay_book/models/stay.dart';
import 'package:stay_book/widgets/calendar_day_cell.dart';

void main() {
  testWidgets('ช่องวันที่ขนาดเล็กที่มีหลายสถานะไม่เกิด overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 34,
            height: 38,
            child: CalendarDayCell(
              day: 28,
              bookingCount: 12,
              statuses: const <int>{
                Stay.statusBooked,
                Stay.statusCheckedIn,
                Stay.statusCheckedOut,
              },
              selected: true,
              today: false,
              onTap: _noop,
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('28'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
  });
}

void _noop() {}
