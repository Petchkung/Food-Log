import 'meal_type.dart';

/// อาหาร 1 รายการที่ผู้ใช้บันทึก
class FoodEntry {
  FoodEntry({
    required this.id,
    required this.userId,
    required String name,
    required double calories,
    double protein = 0,
    double carbs = 0,
    double fat = 0,
    required this.mealType,
    required this.eatenAt,
    DateTime? updatedAt,
    this.synced = false,
    this.deleted = false,
  })  : name = cleanName(name),
        calories = clampNumber(calories, maxCalories),
        protein = clampNumber(protein, maxGrams),
        carbs = clampNumber(carbs, maxGrams),
        fat = clampNumber(fat, maxGrams),
        updatedAt = updatedAt ?? DateTime.now();

  static const double maxCalories = 5000;
  static const double maxGrams = 1000;
  static const int maxNameLength = 80;

  final String id;
  final String userId;
  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final MealType mealType;
  final DateTime eatenAt;
  final DateTime updatedAt;

  /// ส่งขึ้น Firestore แล้วหรือยัง
  final bool synced;

  /// ถูกลบแล้ว แต่ยังรอส่งการลบขึ้น Firestore
  final bool deleted;

  // ---------- ทำความสะอาดข้อมูล (กันค่าแปลก ๆ จากผู้ใช้/API/AI) ----------

  /// ลบ tag HTML, ช่องว่างซ้ำ และตัดความยาว
  static String cleanName(String input) {
    var s = input.replaceAll(RegExp(r'<[^>]*>'), '');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (s.length > maxNameLength) s = s.substring(0, maxNameLength).trim();
    return s;
  }

  /// บังคับตัวเลขให้อยู่ระหว่าง 0 ถึง max
  static double clampNumber(num? value, double max) {
    if (value == null || value.isNaN || value.isInfinite || value < 0) return 0;
    return value > max ? max : value.toDouble();
  }

  /// สร้าง id ไม่ซ้ำ (เวลาปัจจุบัน + ตัวนับ)
  static int _counter = 0;
  static String newId() {
    _counter = (_counter + 1) % 100000;
    final t = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    return '$t-${_counter.toRadixString(36)}';
  }

  FoodEntry copyWith({
    String? name,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    MealType? mealType,
    DateTime? eatenAt,
    DateTime? updatedAt,
    bool? synced,
    bool? deleted,
  }) {
    return FoodEntry(
      id: id,
      userId: userId,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      mealType: mealType ?? this.mealType,
      eatenAt: eatenAt ?? this.eatenAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
      deleted: deleted ?? this.deleted,
    );
  }

  // ---------- SQLite (เวลาเป็นตัวเลข ms, true/false เป็น 1/0) ----------

  Map<String, Object?> toDbMap() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'meal_type': mealType.name,
        'eaten_at': eatenAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'synced': synced ? 1 : 0,
        'deleted': deleted ? 1 : 0,
      };

  factory FoodEntry.fromDbMap(Map<String, Object?> m) => FoodEntry(
        id: m['id'] as String,
        userId: m['user_id'] as String,
        name: m['name'] as String? ?? '',
        calories: (m['calories'] as num?)?.toDouble() ?? 0,
        protein: (m['protein'] as num?)?.toDouble() ?? 0,
        carbs: (m['carbs'] as num?)?.toDouble() ?? 0,
        fat: (m['fat'] as num?)?.toDouble() ?? 0,
        mealType: MealType.fromName(m['meal_type'] as String?),
        eatenAt: DateTime.fromMillisecondsSinceEpoch((m['eaten_at'] as num).toInt()),
        updatedAt: DateTime.fromMillisecondsSinceEpoch((m['updated_at'] as num).toInt()),
        synced: m['synced'] == 1,
        deleted: m['deleted'] == 1,
      );

  // ---------- Firestore (ไม่เก็บ synced/deleted เพราะเป็นสถานะในเครื่อง) ----------

  Map<String, Object?> toCloudMap() => {
        'id': id,
        'userId': userId,
        'name': name,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'mealType': mealType.name,
        'eatenAt': eatenAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
      };

  factory FoodEntry.fromCloudMap(Map<String, Object?> m) => FoodEntry(
        id: m['id'] as String,
        userId: m['userId'] as String,
        name: m['name'] as String? ?? '',
        calories: (m['calories'] as num?)?.toDouble() ?? 0,
        protein: (m['protein'] as num?)?.toDouble() ?? 0,
        carbs: (m['carbs'] as num?)?.toDouble() ?? 0,
        fat: (m['fat'] as num?)?.toDouble() ?? 0,
        mealType: MealType.fromName(m['mealType'] as String?),
        eatenAt: DateTime.fromMillisecondsSinceEpoch((m['eatenAt'] as num).toInt()),
        updatedAt: DateTime.fromMillisecondsSinceEpoch((m['updatedAt'] as num).toInt()),
        synced: true,
      );
}