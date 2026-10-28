import 'package:flutter_test/flutter_test.dart';
import 'package:food_log/data/food_repository.dart';
import 'package:food_log/data/local_database.dart';
import 'package:food_log/models/meal_type.dart';
import 'package:food_log/state/food_log_controller.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/fake_cloud_sync.dart';

void main() {
  late LocalDatabase local;
  late FakeCloudSync cloud;
  late FoodLogController c;

  final now = DateTime(2026, 10, 28, 12, 30);

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    local = await LocalDatabase.open(
        factory: databaseFactoryFfi, path: inMemoryDatabasePath);
    cloud = FakeCloudSync();
    c = FoodLogController(
      repository: FoodRepository(local: local, cloud: cloud),
      uid: 'u1',
      clock: () => now,
    );
    await c.init();
  });

  tearDown(() async {
    c.dispose();
    await local.close();
  });

  test('เริ่มต้น: วันนี้ ยังไม่มีรายการ เป้าหมาย 2000', () {
    expect(c.isToday, isTrue);
    expect(c.entries, isEmpty);
    expect(c.summary.goal, 2000);
    expect(c.loading, isFalse);
  });

  test('เพิ่มอาหาร → อยู่ในรายการวันนี้ ยอดรวมขึ้น และขึ้น cloud', () async {
    await c.addEntry(name: 'ข้าวมันไก่', calories: 520, mealType: MealType.lunch);
    await c.addEntry(name: 'ชาเย็น', calories: 180);

    expect(c.entries, hasLength(2));
    expect(c.summary.calories, 700);
    expect(c.summary.remaining, 1300);
    expect(c.summary.caloriesByMeal[MealType.lunch], 700);
    expect(cloud.store['u1'], hasLength(2));
    expect(c.consumeMessage(), 'บันทึก "ชาเย็น" แล้ว');
    expect(c.consumeMessage(), isNull); // อ่านแล้วหายไป
  });

  test('ลบอาหาร → หายจากรายการ', () async {
    await c.addEntry(name: 'ข้าวผัด', calories: 600);
    await c.deleteEntry(c.entries.single);
    expect(c.entries, isEmpty);
  });

  test('เปลี่ยนวัน: ย้อนไปเมื่อวานได้ แต่ไปอนาคตไม่ได้', () async {
    await c.addEntry(name: 'วันนี้', calories: 100);
    await c.previousDay();
    expect(c.isToday, isFalse);
    expect(c.entries, isEmpty);

    await c.addEntry(name: 'เมื่อวาน', calories: 300);
    expect(c.entries.single.eatenAt.day, 27);

    await c.nextDay();
    expect(c.isToday, isTrue);
    await c.nextDay();
    expect(c.isToday, isTrue); // ยังเป็นวันนี้
    expect(c.entries.single.name, 'วันนี้');
  });

  test('เกินเป้า: progress ไม่เกิน 1 และ isOverGoal เป็นจริง', () async {
    await c.setGoal(1000);
    await c.addEntry(name: 'บุฟเฟต์', calories: 1500);
    expect(c.summary.isOverGoal, isTrue);
    expect(c.summary.progress, 1);
  });

  test('ซิงก์ตอนออฟไลน์ → แจ้งว่าไม่สำเร็จ และนับรายการค้าง', () async {
    cloud.offline = true;
    await c.addEntry(name: 'ข้าวผัด', calories: 600);
    expect(c.pendingCount, 1);

    await c.sync();
    expect(c.consumeMessage(), contains('ไม่สำเร็จ'));

    cloud.offline = false;
    await c.sync();
    expect(c.pendingCount, 0);
  });

  test('history คืนยอดแคลอรี่ย้อนหลังตามจำนวนวัน', () async {
    await c.addEntry(name: 'วันนี้', calories: 500);
    await c.previousDay();
    await c.addEntry(name: 'เมื่อวาน', calories: 800);

    final h = await c.history(7);
    expect(h, hasLength(7));
    expect(h.last.calories, 500);
    expect(h[5].calories, 800);
    expect(h.first.calories, 0);
  });
}