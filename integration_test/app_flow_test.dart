import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_log/app/app.dart';
import 'package:food_log/data/food_repository.dart';
import 'package:food_log/data/local_database.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite/sqflite.dart';

import '../test/helpers/fake_auth_service.dart';
import '../test/helpers/fake_cloud_sync.dart';

/// เทสต์ทั้ง flow บนมือถือจริง: UI จริง + SQLite จริง (Auth และ Cloud เป็นของปลอม)
/// รัน: flutter test integration_test
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late String dbName;
  late LocalDatabase local;
  late FakeCloudSync cloud;
  late FakeAuthService auth;

  setUp(() async {
    dbName = 'integration_${DateTime.now().millisecondsSinceEpoch}.db';
    local = await LocalDatabase.open(
      path: dbName,
    ); // SQLite จริงบนเครื่อง (ไฟล์แยก ไม่ปนข้อมูลจริง)
    cloud = FakeCloudSync();
    auth = FakeAuthService();
  });

  tearDown(() async {
    await local.close();
    await databaseFactorySqflitePlugin.deleteDatabase(dbName);
  });

  Future<void> addFood(WidgetTester tester, String name, String kcal) async {
    await tester.tap(find.byKey(const Key('addFoodButton')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('foodNameField')), name);
    await tester.enterText(find.byKey(const Key('caloriesField')), kcal);
    await tester.tap(find.byKey(const Key('saveFoodButton')));
    await tester.pumpAndSettle();
  }

  Future<void> login(WidgetTester tester) async {
    // ผ่านหน้า Welcome ก่อน
    final start = find.byKey(const Key('welcomeLoginButton'));
    await tester.ensureVisible(start);
    await tester.tap(start);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('emailField')), 'min@test.com');
    await tester.enterText(
      find.byKey(const Key('passwordField')),
      'foodlog2026',
    );
    await tester.tap(find.byKey(const Key('submitButton')));
    await tester.pumpAndSettle();
  }

  /// ตัวเลขแคลอรี่รวมกลางวงแหวน เช่น "700"
  String total(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('calorieTotal'))).data!;

  testWidgets(
    'ล็อกอิน → เพิ่มอาหาร → ออฟไลน์แล้วซิงก์ → ลบ → ออก/เข้าใหม่ ข้อมูลยังอยู่',
    (tester) async {
      await tester.pumpWidget(
        FoodLogApp(
          auth: auth,
          repository: FoodRepository(local: local, cloud: cloud),
        ),
      );
      await tester.pumpAndSettle();

      // 1) ล็อกอิน → หน้าหลักว่าง
      await login(tester);
      expect(find.text('สวัสดี, min'), findsOneWidget);
      expect(find.byKey(const Key('emptyState')), findsOneWidget);

      // 2) เพิ่มอาหาร 2 รายการ → ยอดรวมถูก และขึ้น cloud
      await addFood(tester, 'ข้าวมันไก่', '520');
      await addFood(tester, 'ชาเย็น', '180');
      expect(total(tester), '700');
      expect(cloud.store['test-uid'], hasLength(2));

      // 3) เน็ตหลุด → ยังบันทึกได้ในเครื่อง แล้วซิงก์ทีหลัง
      cloud.offline = true;
      await addFood(tester, 'ส้มตำ', '120');
      expect(total(tester), '820');
      expect(cloud.store['test-uid'], hasLength(2)); // ยังไม่ขึ้น cloud

      cloud.offline = false;
      await tester.tap(find.byKey(const Key('syncButton')));
      await tester.pumpAndSettle();
      expect(cloud.store['test-uid'], hasLength(3)); // ซิงก์แล้ว

      // 4) ลบชาเย็น → ยอดลด และลบบน cloud ด้วย
      final teaTile = find.ancestor(
        of: find.text('ชาเย็น'),
        matching: find.byType(ListTile),
      );
      await tester.tap(
        find.descendant(of: teaTile, matching: find.byTooltip('ลบ')),
      );
      await tester.pumpAndSettle();
      expect(find.text('ชาเย็น'), findsNothing);
      expect(total(tester), '640');
      expect(cloud.store['test-uid'], hasLength(2));

      // 5) ออกจากระบบ แล้วเข้าใหม่ → ข้อมูลยังอยู่ (อ่านจาก SQLite)
      await tester.tap(find.byKey(const Key('signOutButton')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('welcomeStartButton')), findsOneWidget);

      await login(tester);
      expect(find.text('ข้าวมันไก่'), findsOneWidget);
      expect(find.text('ส้มตำ'), findsOneWidget);
      expect(total(tester), '640');
    },
  );
}
