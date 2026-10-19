import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stay_book/models/room.dart';
import 'package:stay_book/screens/manage_rooms_screen.dart';
import 'package:stay_book/theme/app_theme.dart';

const customRoom = Room(
  id: 7,
  name: 'C1',
  zone: 'อาคาร C',
  type: 'เตียงพิเศษ',
  price: 700,
  baseGuests: 2,
  maxGuests: 3,
  extraGuestFee: 100,
  sortOrder: 9,
  status: Room.statusOccupied,
  isPetFriendly: true,
);

Future<void> select(WidgetTester tester, int index, String option) async {
  final dropdown = find.byType(DropdownButtonFormField<String>).at(index);
  await tester.ensureVisible(dropdown);
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

void main() {
  for (final editing in <bool>[false, true]) {
    testWidgets('Room dropdowns submit selected values (editing: $editing)', (
      tester,
    ) async {
      Room? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await showDialog<Room>(
                    context: context,
                    builder: (_) => RoomFormDialog(
                      existing: editing ? customRoom : null,
                      rooms: const <Room>[customRoom, customRoom],
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final fields = tester
          .widgetList<DropdownButtonFormField<String>>(
            find.byType(DropdownButtonFormField<String>),
          )
          .toList();
      expect(fields[0].initialValue, editing ? customRoom.zone : 'อาคารหลัก');
      expect(fields[1].initialValue, editing ? customRoom.type : 'เตียงคู่');
      if (!editing) {
        await tester.enterText(find.byType(TextFormField).at(0), '12');
        await tester.enterText(find.byType(TextFormField).at(1), '500');
        await tester.enterText(find.byType(TextFormField).at(4), '0');
      }
      await select(tester, 0, editing ? 'โซน B' : customRoom.zone);
      await select(tester, 1, editing ? 'เตียงเดี่ยว' : customRoom.type);
      await tester.tap(
        find.widgetWithText(
          FilledButton,
          editing ? 'บันทึกการแก้ไข' : 'เพิ่มห้อง',
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(result, isNotNull);
      expect(result!.zone, editing ? 'โซน B' : customRoom.zone);
      expect(result!.type, editing ? 'เตียงเดี่ยว' : customRoom.type);
      expect(result!.id, editing ? customRoom.id : null);
      if (editing) {
        expect(result!.sortOrder, customRoom.sortOrder);
        expect(result!.status, customRoom.status);
        expect(result!.isPetFriendly, isTrue);
      }
    });
  }
}
