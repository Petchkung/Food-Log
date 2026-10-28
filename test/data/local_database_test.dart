import 'package:flutter_test/flutter_test.dart';
import 'package:food_log/data/local_database.dart';
import 'package:food_log/models/food_entry.dart';
import 'package:food_log/models/meal_type.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late LocalDatabase db;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    db = await LocalDatabase.open(
        factory: databaseFactoryFfi, path: inMemoryDatabasePath);
  });

  tearDown(() => db.close());

  FoodEntry entry(String id,
          {String user = 'u1',
          required DateTime at,
          String name = 'ข้าวผัด',
          bool synced = false}) =>
      FoodEntry(
        id: id,
        userId: user,
        name: name,
        calories: 500,
        mealType: MealType.lunch,
        eatenAt: at,
        synced: synced,
      );

  final today = DateTime(2026, 10, 28, 12);
  final yesterday = DateTime(2026, 10, 27, 12);

  test('บันทึกแล้วอ่านกลับได้ เฉพาะวันที่ขอ และเรียงตามเวลา', () async {
    await db.upsert(entry('b', at: today.add(const Duration(hours: 6))));
    await db.upsert(entry('a', at: today));
    await db.upsert(entry('c', at: yesterday));

    final list = await db.entriesForDay('u1', today);
    expect(list.map((e) => e.id), ['a', 'b']);
  });

  test('upsert id เดิม = แก้ไข ไม่ได้เพิ่มรายการใหม่', () async {
    await db.upsert(entry('a', at: today));
    await db.upsert(entry('a', at: today, name: 'ข้าวมันไก่'));

    final list = await db.entriesForDay('u1', today);
    expect(list, hasLength(1));
    expect(list.single.name, 'ข้าวมันไก่');
  });

  test('รายการที่ถูกลบ (soft delete) ไม่แสดง แต่ยังรอ sync', () async {
    await db.upsert(entry('a', at: today).copyWith(deleted: true));

    expect(await db.entriesForDay('u1', today), isEmpty);
    expect((await db.pendingSync('u1')).single.deleted, isTrue);
  });

  test('pendingSync คืนเฉพาะรายการที่ยังไม่ส่งขึ้น cloud', () async {
    await db.upsert(entry('a', at: today, synced: true));
    await db.upsert(entry('b', at: today));

    final pending = await db.pendingSync('u1');
    expect(pending.map((e) => e.id), ['b']);
  });

  test('hardDelete ลบออกจากเครื่องจริง', () async {
    await db.upsert(entry('a', at: today));
    await db.hardDelete('u1', 'a');
    expect(await db.getEntry('u1', 'a'), isNull);
  });

  test('เป้าหมายแคลอรี่: ยังไม่ตั้ง = null, ตั้งแล้วอ่านได้, ตั้งซ้ำ = ทับ', () async {
    expect(await db.getDailyGoal('u1'), isNull);
    await db.setDailyGoal('u1', 1800);
    await db.setDailyGoal('u1', 2000);
    expect(await db.getDailyGoal('u1'), 2000);
  });

  group('ความปลอดภัย', () {
    test('ผู้ใช้คนหนึ่งมองไม่เห็นข้อมูลของอีกคน', () async {
      await db.upsert(entry('a', user: 'alice', at: today));
      await db.upsert(entry('b', user: 'bob', at: today));

      final aliceList = await db.entriesForDay('alice', today);
      expect(aliceList.map((e) => e.id), ['a']);
      expect(await db.getEntry('alice', 'b'), isNull);
      expect(await db.pendingSync('alice'), hasLength(1));
    });

    test('ชื่ออาหารที่มีคำสั่ง SQL ถูกเก็บเป็นข้อความธรรมดา (กัน SQL injection)', () async {
      const evil = "x'); DROP TABLE food_entries; --";
      await db.upsert(entry('a', at: today, name: evil));

      final saved = await db.getEntry('u1', 'a');
      expect(saved!.name, evil);
      expect(await db.entriesForDay('u1', today), hasLength(1)); // ตารางยังอยู่
    });
  });
}