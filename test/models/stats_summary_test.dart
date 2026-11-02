import 'package:flutter_test/flutter_test.dart';
import 'package:food_log/models/stats_summary.dart';

void main() {
  DayCalories day(int d, double kcal) =>
      (day: DateTime(2026, 10, d), calories: kcal);

  test('เฉลี่ยและนับเกินเป้า เฉพาะวันที่มีบันทึก', () {
    final s = StatsSummary.fromDays([
      day(24, 0),
      day(25, 1500),
      day(26, 2500),
      day(27, 0),
      day(28, 1900),
    ], 2000);

    expect(s.loggedDays, 3);
    expect(s.averageCalories, closeTo(5900 / 3, 0.001));
    expect(s.daysOverGoal, 1);
  });

  test('เท่ากับเป้าพอดี ไม่นับว่าเกินเป้า', () {
    final s = StatsSummary.fromDays([day(27, 2000), day(28, 2001)], 2000);

    expect(s.daysOverGoal, 1);
  });

  test('ไม่มีบันทึกเลย → ทุกค่าเป็น 0', () {
    final s = StatsSummary.fromDays([day(27, 0), day(28, 0)], 2000);

    expect(s.loggedDays, 0);
    expect(s.averageCalories, 0);
    expect(s.daysOverGoal, 0);
  });

  test('รายการว่าง → ทุกค่าเป็น 0', () {
    final s = StatsSummary.fromDays(const [], 2000);

    expect(s.loggedDays, 0);
    expect(s.averageCalories, 0);
  });
}
