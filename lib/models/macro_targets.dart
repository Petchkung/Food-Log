/// เป้าหมายสารอาหารต่อวัน (หน่วยกรัม) คำนวณจากเป้าแคลอรี่
///
/// สัดส่วนพลังงาน: โปรตีน 20% / คาร์บ 50% / ไขมัน 30%
/// (โปรตีนและคาร์บ 4 kcal ต่อกรัม, ไขมัน 9 kcal ต่อกรัม)
class MacroTargets {
  const MacroTargets({
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory MacroTargets.fromCalories(double calories) {
    final kcal = calories < 0 ? 0.0 : calories;
    return MacroTargets(
      protein: kcal * 0.20 / 4,
      carbs: kcal * 0.50 / 4,
      fat: kcal * 0.30 / 9,
    );
  }

  final double protein;
  final double carbs;
  final double fat;
}
