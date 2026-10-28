import 'package:flutter_test/flutter_test.dart';
import 'package:food_log/models/food_entry.dart';
import 'package:food_log/models/meal_type.dart';

void main() {
  FoodEntry sample({String name = 'ข้าวมันไก่', double calories = 520}) => FoodEntry(
        id: 'e1',
        userId: 'u1',
        name: name,
        calories: calories,
        protein: 28,
        carbs: 62,
        fat: 18,
        mealType: MealType.lunch,
        eatenAt: DateTime(2026, 10, 28, 12, 30),
        updatedAt: DateTime(2026, 10, 28, 12, 31),
      );

  group('ทำความสะอาดข้อมูล', () {
    test('ลบ tag HTML และช่องว่างซ้ำออกจากชื่อ', () {
      final e = sample(name: '  <b>ข้าว</b>   ผัด  ');
      expect(e.name, 'ข้าว ผัด');
    });

    test('ตัดชื่อที่ยาวเกิน 80 ตัวอักษร', () {
      expect(sample(name: 'ก' * 200).name.length, FoodEntry.maxNameLength);
    });

    test('แคลอรี่ติดลบหรือมากเกินถูกบังคับให้อยู่ในช่วง', () {
      expect(sample(calories: -50).calories, 0);
      expect(sample(calories: 999999).calories, FoodEntry.maxCalories);
      expect(sample(calories: double.nan).calories, 0);
    });
  });

  group('แปลงข้อมูลไป-กลับ', () {
    test('SQLite: toDbMap → fromDbMap ได้ค่าเดิม', () {
      final e = sample().copyWith(synced: true);
      final back = FoodEntry.fromDbMap(e.toDbMap());
      expect(back.name, e.name);
      expect(back.calories, e.calories);
      expect(back.mealType, MealType.lunch);
      expect(back.eatenAt, e.eatenAt);
      expect(back.synced, isTrue);
      expect(back.deleted, isFalse);
    });

    test('Firestore: ไม่ส่งสถานะ synced/deleted ขึ้น cloud', () {
      final map = sample().toCloudMap();
      expect(map.containsKey('synced'), isFalse);
      expect(map.containsKey('deleted'), isFalse);
      final back = FoodEntry.fromCloudMap(map);
      expect(back.userId, 'u1');
      expect(back.synced, isTrue);
    });
  });

  test('copyWith เปลี่ยนเฉพาะค่าที่ระบุ', () {
    final e = sample().copyWith(calories: 300, mealType: MealType.dinner);
    expect(e.calories, 300);
    expect(e.mealType, MealType.dinner);
    expect(e.name, 'ข้าวมันไก่');
    expect(e.id, 'e1');
  });

  test('newId ไม่ซ้ำกัน', () {
    final ids = {for (var i = 0; i < 100; i++) FoodEntry.newId()};
    expect(ids.length, 100);
  });

  group('MealType', () {
    test('fromName แปลงชื่อที่รู้จัก และชื่อแปลกเป็นของว่าง', () {
      expect(MealType.fromName('dinner'), MealType.dinner);
      expect(MealType.fromName('xyz'), MealType.snack);
      expect(MealType.fromName(null), MealType.snack);
    });

    test('suggestFor เดามื้อจากเวลา', () {
      expect(MealType.suggestFor(DateTime(2026, 1, 1, 8)), MealType.breakfast);
      expect(MealType.suggestFor(DateTime(2026, 1, 1, 12)), MealType.lunch);
      expect(MealType.suggestFor(DateTime(2026, 1, 1, 19)), MealType.dinner);
      expect(MealType.suggestFor(DateTime(2026, 1, 1, 23)), MealType.snack);
    });
  });
}