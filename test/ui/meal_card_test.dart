import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_log/models/food_entry.dart';
import 'package:food_log/models/meal_type.dart';
import 'package:food_log/ui/widgets/meal_card.dart';

void main() {
  FoodEntry entry(String id, String name, double kcal) => FoodEntry(
    id: id,
    userId: 'u1',
    name: name,
    calories: kcal,
    mealType: MealType.lunch,
    eatenAt: DateTime(2026, 10, 28, 12),
  );

  Widget wrap({
    List<FoodEntry> entries = const [],
    double calories = 0,
    VoidCallback? onAdd,
    ValueChanged<FoodEntry>? onDelete,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: MealCard(
            meal: MealType.lunch,
            calories: calories,
            entries: entries,
            onAdd: onAdd ?? () {},
            onDelete: onDelete ?? (_) {},
          ),
        ),
      ),
    );
  }

  String title(WidgetTester tester) => tester
      .widget<Text>(find.byKey(const Key('mealTitle_lunch')))
      .textSpan!
      .toPlainText();

  testWidgets(
    'มื้อว่าง → ชื่อมื้อกับข้อความ "ยังไม่มีรายการ" และไม่มีแคลอรี่',
    (tester) async {
      await tester.pumpWidget(wrap());

      expect(title(tester), 'มื้อกลางวัน');
      expect(find.text('ยังไม่มีรายการ'), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
    },
  );

  testWidgets('มีรายการ → แสดงแคลอรี่รวมและรายการอาหาร', (tester) async {
    await tester.pumpWidget(
      wrap(
        calories: 820,
        entries: [entry('e1', 'ข้าวมันไก่', 520), entry('e2', 'ชาเย็น', 300)],
      ),
    );

    expect(title(tester), 'มื้อกลางวัน · 820 kcal');
    expect(find.text('ข้าวมันไก่'), findsOneWidget);
    expect(find.text('ชาเย็น'), findsOneWidget);
    expect(find.text('520 kcal'), findsOneWidget);
    expect(find.text('ยังไม่มีรายการ'), findsNothing);
  });

  testWidgets('กดปุ่ม + → เรียก onAdd', (tester) async {
    var calls = 0;
    await tester.pumpWidget(wrap(onAdd: () => calls++));

    await tester.tap(find.byKey(const Key('addMeal_lunch')));
    expect(calls, 1);
  });

  testWidgets('กดลบที่รายการ → เรียก onDelete พร้อมรายการนั้น', (tester) async {
    FoodEntry? deleted;
    await tester.pumpWidget(
      wrap(
        calories: 820,
        entries: [entry('e1', 'ข้าวมันไก่', 520), entry('e2', 'ชาเย็น', 300)],
        onDelete: (e) => deleted = e,
      ),
    );

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('e2')),
        matching: find.byTooltip('ลบ'),
      ),
    );
    expect(deleted?.id, 'e2');
  });
}
