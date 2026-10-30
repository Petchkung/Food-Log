import 'food_entry.dart';

/// ข้อมูลโภชนาการจาก API หรือ AI (ค่าต่อ [servingGrams] กรัม) — ยังไม่ใช่รายการที่บันทึก
class NutritionInfo {
  NutritionInfo({
    required String name,
    String? brand,
    required double calories,
    double protein = 0,
    double carbs = 0,
    double fat = 0,
    this.servingGrams = 100,
    this.confidence,
  })  : name = FoodEntry.cleanName(name),
        brand = brand == null ? null : FoodEntry.cleanName(brand),
        calories = FoodEntry.clampNumber(calories, FoodEntry.maxCalories),
        protein = FoodEntry.clampNumber(protein, FoodEntry.maxGrams),
        carbs = FoodEntry.clampNumber(carbs, FoodEntry.maxGrams),
        fat = FoodEntry.clampNumber(fat, FoodEntry.maxGrams);

  final String name;
  final String? brand;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double servingGrams;

  /// ความมั่นใจของ AI (0–1) — ข้อมูลจาก API ไม่มีค่านี้
  final double? confidence;

  /// ปรับค่าตามปริมาณที่กินจริง เช่น 100 g → 250 g
  NutritionInfo scaledTo(double grams) {
    if (grams <= 0 || servingGrams <= 0) return this;
    final f = grams / servingGrams;
    return NutritionInfo(
      name: name,
      brand: brand,
      calories: calories * f,
      protein: protein * f,
      carbs: carbs * f,
      fat: fat * f,
      servingGrams: grams,
      confidence: confidence,
    );
  }
}