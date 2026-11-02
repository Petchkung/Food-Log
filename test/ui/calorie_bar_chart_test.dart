import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_log/models/stats_summary.dart';
import 'package:food_log/ui/widgets/calorie_bar_chart.dart';

void main() {
  /// รายวันเริ่ม พฤ 22 ต.ค. 2026 (วันสุดท้าย = พุธ 28 ต.ค. = "วันนี้")
  List<DayCalories> days(List<double> values) => [
    for (var i = 0; i < values.length; i++)
      (day: DateTime(2026, 10, 22 + i), calories: values[i]),
  ];

  Widget wrap(List<DayCalories> data, double goal) => MaterialApp(
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: CalorieBarChart(days: data, goal: goal),
      ),
    ),
  );

  Color? barColor(WidgetTester tester, int i) =>
      (tester.widget<DecoratedBox>(find.byKey(Key('statsBar_$i'))).decoration
              as BoxDecoration)
          .color;

  ColorScheme schemeOf(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(CalorieBarChart))).colorScheme;

  testWidgets('7 วัน → 7 แท่ง ป้ายวันถูก และแท่งสุดท้ายเป็น "วันนี้"', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(days([1000, 1500, 0, 1800, 1200, 900, 1600]), 2000),
    );

    expect(find.byKey(const Key('statsBar_6')), findsOneWidget);
    expect(find.byKey(const Key('statsBar_7')), findsNothing);
    for (final label in ['พฤ', 'ศ', 'ส', 'อา', 'จ', 'อ', 'วันนี้']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('แท่งที่เกินเป้าเป็นสีแดง ที่เหลือเป็นสีหลัก และวันนี้เข้มกว่า', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(days([1000, 2500, 0, 1800, 1200, 900, 1600]), 2000),
    );
    final scheme = schemeOf(tester);

    expect(barColor(tester, 1), scheme.error); // 2,500 เกินเป้า
    expect(barColor(tester, 0), scheme.primary.withValues(alpha: 0.45));
    expect(barColor(tester, 6), scheme.primary); // วันนี้ ไม่เกินเป้า
  });

  testWidgets('ความสูงแท่งเป็นสัดส่วนกับแคลอรี่ และวันที่ว่างสูง 0', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(days([1250, 2500, 0, 0, 0, 0, 0]), 2000));

    final short = tester.getSize(find.byKey(const Key('statsBar_0'))).height;
    final tall = tester.getSize(find.byKey(const Key('statsBar_1'))).height;
    final empty = tester.getSize(find.byKey(const Key('statsBar_2'))).height;

    expect(tall / short, closeTo(2, 0.01));
    expect(empty, 0);
  });

  testWidgets('30 วัน → 30 แท่ง ป้ายวันที่ทุก 5 วันและ "วันนี้"', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(days(List.filled(30, 0)), 2000));

    expect(find.byKey(const Key('statsBar_29')), findsOneWidget);
    expect(find.byKey(const Key('statsBar_30')), findsNothing);
    expect(find.text('วันนี้'), findsOneWidget);
    expect(
      find.text('พฤ'),
      findsNothing,
    ); // โหมดเดือนใช้เลขวันที่ ไม่ใช่ชื่อวัน
  });
}
