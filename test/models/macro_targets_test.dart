import 'package:flutter_test/flutter_test.dart';
import 'package:food_log/models/macro_targets.dart';

void main() {
  test('เป้า 1,800 kcal → โปรตีน 90 / คาร์บ 225 / ไขมัน 60 กรัม', () {
    final t = MacroTargets.fromCalories(1800);
    expect(t.protein, closeTo(90, 0.001));
    expect(t.carbs, closeTo(225, 0.001));
    expect(t.fat, closeTo(60, 0.001));
  });

  test('เป้า 2,000 kcal', () {
    final t = MacroTargets.fromCalories(2000);
    expect(t.protein, closeTo(100, 0.001));
    expect(t.carbs, closeTo(250, 0.001));
    expect(t.fat, closeTo(66.67, 0.01));
  });

  test('เป้า 0 หรือติดลบ → ทุกค่าเป็น 0', () {
    for (final goal in [0.0, -100.0]) {
      final t = MacroTargets.fromCalories(goal);
      expect(t.protein, 0);
      expect(t.carbs, 0);
      expect(t.fat, 0);
    }
  });
}
