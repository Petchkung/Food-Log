import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_log/app/app.dart';
import 'package:food_log/models/food_entry.dart';
import 'package:food_log/models/meal_type.dart';

import '../helpers/fake_auth_service.dart';
import '../helpers/fake_food_repository.dart';

void main() {
  late FakeAuthService auth;
  late FakeFoodRepository repo;

  setUp(() async {
    auth = FakeAuthService();
    repo = FakeFoodRepository();
    await auth.signIn(
      email: 'min@test.com',
      password: 'foodlog2026',
    ); // ล็อกอินไว้ก่อน
  });

  Future<void> openApp(WidgetTester tester) async {
    await tester.pumpWidget(FoodLogApp(auth: auth, repository: repo));
    await tester.pumpAndSettle();
  }

  /// ตัวเลขแคลอรี่รวมกลางวงแหวน เช่น "520"
  String totalText(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('calorieTotal'))).data!;

  testWidgets('ยังไม่มีรายการ → แสดงข้อความว่าง และ 0 จาก 2,000 kcal', (
    tester,
  ) async {
    await openApp(tester);
    expect(find.byKey(const Key('emptyState')), findsOneWidget);
    expect(totalText(tester), '0'); // ปรับ
    expect(find.text('จาก 2,000 kcal'), findsOneWidget); // ปรับ
  });

  testWidgets('เพิ่มอาหารผ่านกล่องเพิ่มอาหาร → เห็นในรายการ และยอดรวมอัปเดต', (
    tester,
  ) async {
    await openApp(tester);

    await tester.tap(find.byKey(const Key('addFoodButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('foodNameField')),
      'ข้าวมันไก่',
    );
    await tester.enterText(find.byKey(const Key('caloriesField')), '520');
    await tester.tap(find.text('มื้อกลางวัน'));
    await tester.tap(find.byKey(const Key('saveFoodButton')));
    await tester.pumpAndSettle();

    expect(find.text('ข้าวมันไก่'), findsOneWidget);
    expect(totalText(tester), '520'); // ปรับ
    expect(repo.items.single.mealType, MealType.lunch);
  });

  testWidgets('กล่องเพิ่มอาหาร: ไม่กรอก → แจ้งเตือน และไม่บันทึก', (
    tester,
  ) async {
    await openApp(tester);

    await tester.tap(find.byKey(const Key('addFoodButton')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('caloriesField')), 'abc');
    await tester.tap(find.byKey(const Key('saveFoodButton')));
    await tester.pumpAndSettle();

    expect(find.text('กรุณากรอกชื่ออาหาร'), findsOneWidget);
    expect(find.text('กรุณากรอกเป็นตัวเลข'), findsOneWidget);
    expect(repo.items, isEmpty);
  });

  testWidgets('กดลบ → รายการหายไป', (tester) async {
    repo.items.add(
      FoodEntry(
        id: 'e1',
        userId: 'test-uid',
        name: 'ส้มตำ',
        calories: 120,
        mealType: MealType.lunch,
        eatenAt: DateTime.now(),
      ),
    );
    await openApp(tester);
    expect(find.text('ส้มตำ'), findsOneWidget);

    await tester.tap(find.byTooltip('ลบ'));
    await tester.pumpAndSettle();

    expect(find.text('ส้มตำ'), findsNothing);
    expect(repo.items, isEmpty);
  });

  testWidgets('กดปุ่มซิงก์ → เรียก sync ที่ repository', (tester) async {
    await openApp(tester);
    final before = repo.syncCalls; // ตอนเปิดหน้า sync อัตโนมัติไปแล้ว 1 ครั้ง

    await tester.tap(find.byKey(const Key('syncButton')));
    await tester.pumpAndSettle();

    expect(repo.syncCalls, before + 1);
    expect(find.text('ซิงก์ข้อมูลกับ Cloud เรียบร้อย'), findsOneWidget);
  });
}
