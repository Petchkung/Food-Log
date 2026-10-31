import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_log/models/daily_summary.dart';
import 'package:food_log/ui/widgets/calorie_ring_card.dart';

void main() {
  Widget build(double calories, double goal, {bool isToday = true}) {
    return MaterialApp(
      home: Scaffold(
        body: CalorieRingCard(
          summary: DailySummary(
            calories: calories,
            protein: 0,
            carbs: 0,
            fat: 0,
            goal: goal,
            caloriesByMeal: const {},
          ),
          isToday: isToday,
        ),
      ),
    );
  }

  double ringValue(WidgetTester tester) => tester
      .widget<CircularProgressIndicator>(find.byKey(const Key('calorieRing')))
      .value!;

  testWidgets('ยังไม่เกินเป้า → แสดงยอด เป้า และเหลืออีก', (tester) async {
    await tester.pumpWidget(build(1240, 1800));

    expect(find.text('1,240'), findsOneWidget);
    expect(find.text('จาก 1,800 kcal'), findsOneWidget);
    expect(find.text('เหลืออีก'), findsOneWidget);
    expect(find.text('560'), findsOneWidget);
    expect(find.text('kcal สำหรับวันนี้'), findsOneWidget);
    expect(ringValue(tester), closeTo(1240 / 1800, 0.001));
  });

  testWidgets('เกินเป้า → แสดงเกินเป้า และวงแหวนเต็ม', (tester) async {
    await tester.pumpWidget(build(2100, 1800));

    expect(find.text('เกินเป้า'), findsOneWidget);
    expect(find.text('300'), findsOneWidget);
    expect(find.text('เหลืออีก'), findsNothing);
    expect(ringValue(tester), 1.0);
  });

  testWidgets('ดูย้อนหลัง (ไม่ใช่วันนี้) → ไม่เขียนว่า "สำหรับวันนี้"', (
    tester,
  ) async {
    await tester.pumpWidget(build(500, 1800, isToday: false));

    expect(find.text('kcal สำหรับวันนี้'), findsNothing);
    expect(find.text('kcal'), findsOneWidget);
  });
}
