import 'package:flutter_test/flutter_test.dart';
import 'package:food_log/data/food_repository.dart';
import 'package:food_log/data/local_database.dart';
import 'package:food_log/models/food_entry.dart';
import 'package:food_log/models/meal_type.dart';
import 'package:food_log/services/cloud_sync_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/fake_cloud_sync.dart';

void main() {
  late LocalDatabase local;
  late FakeCloudSync cloud;
  late FoodRepository repo;

  final today = DateTime(2026, 10, 28, 12);

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    local = await LocalDatabase.open(
        factory: databaseFactoryFfi, path: inMemoryDatabasePath);
    cloud = FakeCloudSync();
    repo = FoodRepository(local: local, cloud: cloud);
  });

  tearDown(() => local.close());

  FoodEntry entry(String id, {String user = 'u1'}) => FoodEntry(
        id: id,
        userId: user,
        name: 'ข้าวมันไก่',
        calories: 520,
        mealType: MealType.lunch,
        eatenAt: today,
      );

  test('ออนไลน์: บันทึกแล้วขึ้น cloud ทันที', () async {
    final ok = await repo.save('u1', entry('e1'));

    expect(ok, isTrue);
    expect(cloud.store['u1']!.containsKey('e1'), isTrue);
    expect(await repo.pendingCount('u1'), 0);
  });

  test('ออฟไลน์: บันทึกในเครื่องได้ แล้ว sync ขึ้น cloud ทีหลัง', () async {
    cloud.offline = true;
    final ok = await repo.save('u1', entry('e1'));

    expect(ok, isFalse);
    expect(await repo.entriesForDay('u1', today), hasLength(1)); // ยังเห็นในแอป
    expect(await repo.pendingCount('u1'), 1);

    cloud.offline = false;
    final result = await repo.sync('u1');

    expect(result.uploaded, 1);
    expect(cloud.store['u1']!.containsKey('e1'), isTrue);
    expect(await repo.pendingCount('u1'), 0);
  });

  test('ลบตอนออฟไลน์: หายจากหน้าจอทันที และลบบน cloud ตอน sync', () async {
    await repo.save('u1', entry('e1'));
    cloud.offline = true;
    await repo.delete('u1', 'e1');

    expect(await repo.entriesForDay('u1', today), isEmpty);
    expect(cloud.store['u1']!.containsKey('e1'), isTrue); // ยังไม่ได้ลบบน cloud

    cloud.offline = false;
    final result = await repo.sync('u1');
    expect(result.deleted, 1);
    expect(cloud.store['u1']!.containsKey('e1'), isFalse);
  });

  test('sync ดึงข้อมูลจาก cloud ลงเครื่อง (เช่น ล็อกอินเครื่องใหม่)', () async {
    cloud.store['u1'] = {'e9': entry('e9').copyWith(synced: true)};

    final result = await repo.sync('u1');

    expect(result.downloaded, 1);
    expect((await repo.entriesForDay('u1', today)).single.id, 'e9');
  });

  test('sync ตอนออฟไลน์ไม่พัง แค่รายงานว่าล้มเหลว', () async {
    cloud.offline = true;
    final result = await repo.sync('u1');
    expect(result.hasFailures, isTrue);
  });

  test('เป้าหมายแคลอรี่: ค่าเริ่มต้น 2000 และถูกจำกัดช่วง 800–6000', () async {
    expect(await repo.dailyGoal('u1'), 2000);
    await repo.setDailyGoal('u1', 100);
    expect(await repo.dailyGoal('u1'), 800);
    await repo.setDailyGoal('u1', 99999);
    expect(await repo.dailyGoal('u1'), 6000);
  });

  group('ความปลอดภัย', () {
    test('บันทึกข้อมูลในนามผู้ใช้อื่นไม่ได้', () async {
      await expectLater(repo.save('u1', entry('e1', user: 'attacker')),
          throwsA(isA<CloudSyncException>()));
      expect(await local.getEntry('attacker', 'e1'), isNull);
    });

    test('ข้อมูลบน cloud ของคนอื่นไม่ถูกดึงลงมา', () async {
      cloud.store['u1'] = {'x': entry('x', user: 'someone-else')};
      await repo.sync('u1');
      expect(await repo.entriesForDay('u1', today), isEmpty);
    });

    test('id ที่พยายามเจาะ path ถูกปฏิเสธ', () {
      expect(() => CloudSyncService.assertSafeId('abc/../other'),
          throwsA(isA<CloudSyncException>()));
      expect(() => CloudSyncService.assertSafeId(''),
          throwsA(isA<CloudSyncException>()));
      expect(() => CloudSyncService.assertSafeId('u1-ok_123'), returnsNormally);
    });
  });
}