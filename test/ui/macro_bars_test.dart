import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_log/models/daily_summary.dart';
import 'package:food_log/ui/widgets/calorie_ring_card.dart';
import 'package:food_log/ui/widgets/macro_bars.dart';

void main() {
  DailySummary summary({
    double protein = 60,
    double carbs = 140,
    double fat = 30,
    double goal = 1800,
  }) => DailySummary(
    calories: 0,
    protein: protein,
    carbs: carbs,
    fat: fat,
    goal: goal,
    caloriesByMeal: const {},
  );

  /// ข้อความ "60 / 90 g" ของแถบนั้น
  String valueOf(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(Key(key))).textSpan!.toPlainText();

  double barOf(WidgetTester tester, String key) =>
      tester.widget<LinearProgressIndicator>(find.byKey(Key(key))).value!;

  Widget wrap(Widget child) => MaterialApp(
    home: Scaffold(
      body: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  );

  testWidgets('แสดงโปรตีน คาร์บ ไขมัน เทียบกับเป้า', (tester) async {
    await tester.pumpWidget(wrap(MacroBars(summary: summary())));

    expect(find.text('โปรตีน'), findsOneWidget);
    expect(find.text('คาร์บ'), findsOneWidget);
    expect(find.text('ไขมัน'), findsOneWidget);

    expect(valueOf(tester, 'macroProteinValue'), '60 / 90 g');
    expect(valueOf(tester, 'macroCarbsValue'), '140 / 225 g');
    expect(valueOf(tester, 'macroFatValue'), '30 / 60 g');

    expect(barOf(tester, 'macroProteinBar'), closeTo(60 / 90, 0.001));
    expect(barOf(tester, 'macroCarbsBar'), closeTo(140 / 225, 0.001));
    expect(barOf(tester, 'macroFatBar'), closeTo(0.5, 0.001));
  });

  testWidgets('กินเกินเป้า → แถบเต็ม ไม่ล้น', (tester) async {
    await tester.pumpWidget(wrap(MacroBars(summary: summary(protein: 200))));

    expect(valueOf(tester, 'macroProteinValue'), '200 / 90 g');
    expect(barOf(tester, 'macroProteinBar'), 1.0);
  });

  testWidgets('ยังไม่กินอะไร → แถบว่างทั้งหมด', (tester) async {
    await tester.pumpWidget(
      wrap(MacroBars(summary: summary(protein: 0, carbs: 0, fat: 0))),
    );

    expect(barOf(tester, 'macroProteinBar'), 0);
    expect(barOf(tester, 'macroCarbsBar'), 0);
    expect(barOf(tester, 'macroFatBar'), 0);
  });

  testWidgets('แถบสารอาหารอยู่ในการ์ดวงแหวนแคลอรี่', (tester) async {
    await tester.pumpWidget(
      wrap(CalorieRingCard(summary: summary(), isToday: true)),
    );

    expect(find.byKey(const Key('calorieRing')), findsOneWidget);
    expect(find.byKey(const Key('macroProteinBar')), findsOneWidget);
    expect(valueOf(tester, 'macroProteinValue'), '60 / 90 g');
  });
}
