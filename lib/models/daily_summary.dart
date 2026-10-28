import 'food_entry.dart';
import 'meal_type.dart';

/// สรุปแคลอรี่และสารอาหารของหนึ่งวัน
class DailySummary {
  const DailySummary({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.goal,
    required this.caloriesByMeal,
  });

  factory DailySummary.fromEntries(Iterable<FoodEntry> entries, {required double goal}) {
    double cal = 0, p = 0, c = 0, f = 0;
    final byMeal = {for (final m in MealType.values) m: 0.0};
    for (final e in entries) {
      if (e.deleted) continue;
      cal += e.calories;
      p += e.protein;
      c += e.carbs;
      f += e.fat;
      byMeal[e.mealType] = byMeal[e.mealType]! + e.calories;
    }
    return DailySummary(
        calories: cal, protein: p, carbs: c, fat: f, goal: goal, caloriesByMeal: byMeal);
  }

  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double goal;
  final Map<MealType, double> caloriesByMeal;

  double get remaining => goal - calories;
  bool get isOverGoal => calories > goal;

  /// 0.0–1.0 สำหรับวงแหวน / แถบความคืบหน้า
  double get progress {
    if (goal <= 0) return 0;
    final p = calories / goal;
    return p > 1 ? 1 : p;
  }
}