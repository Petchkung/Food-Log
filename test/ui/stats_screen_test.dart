import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_log/app/app.dart';
import 'package:food_log/models/food_entry.dart';
import 'package:food_log/models/meal_type.dart';

import '../helpers/fake_ai_food_analyzer.dart';
import '../helpers/fake_auth_service.dart';
import '../helpers/fake_food_api_service.dart';
import '../helpers/fake_food_repository.dart';

void main() {
  late FakeAuthService auth;
  late FakeFoodRepository repo;

  setUp(() async {
    auth = FakeAuthService();
    repo = FakeFoodRepository();
    await auth.signIn(email: 'min@test.com', password: 'foodlog2026');
  });

  Future<void> openStats(WidgetTester tester) async {
    tester.view.physicalSize = const Size(500, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      FoodLogApp(
        auth: auth,
        repository: repo,
        foodApi: FakeFoodApiService(),
        aiAnalyzer: FakeAiFoodAnalyzer(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('navStats')));
    await tester.pumpAndSettle();
  }

  String textOf(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(Key(key))).data!;

  FoodEntry entry(String id, double kcal, int daysAgo) {
    final now = DateTime.now();
    return FoodEntry(
      id: id,
      userId: 'test-uid',
      name: 'อาหาร $id',
      calories: kcal,
      mealType: MealType.lunch,
      eatenAt: DateTime(now.year, now.month, now.day - daysAgo, 12),
    );
  }

  testWidgets('ยังไม่มีข้อมูล → ข้อความว่าง และสรุปเป็น 0', (tester) async {
    await openStats(tester);

    expect(find.byKey(const Key('statsEmpty')), findsOneWidget);
    expect(textOf(tester, 'statsAverage'), '0');
    expect(textOf(tester, 'statsOverDays'), '0');
    expect(textOf(tester, 'statsLoggedDays'), '0');
    expect(textOf(tester, 'statsGoalLabel'), 'เป้าหมาย 2,000 kcal');
  });

  testWidgets('สัปดาห์ → นับเฉพาะ 7 วันล่าสุด และสีแท่งถูกต้อง', (
    tester,
  ) async {
    repo.items.addAll([
      entry('a', 1500, 0), // วันนี้
      entry('b', 2500, 1), // เมื่อวาน เกินเป้า
      entry('c', 1900, 3),
      entry('d', 2200, 10), // นอกสัปดาห์
    ]);
    await openStats(tester);

    expect(textOf(tester, 'statsLoggedDays'), '3');
    expect(textOf(tester, 'statsAverage'), '1,967'); // (1500+2500+1900)/3
    expect(textOf(tester, 'statsOverDays'), '1');
    expect(find.byKey(const Key('statsEmpty')), findsNothing);
    expect(find.byKey(const Key('statsBar_6')), findsOneWidget);
    expect(find.byKey(const Key('statsBar_7')), findsNothing);

    final scheme = Theme.of(
      tester.element(find.byKey(const Key('statsRange'))),
    ).colorScheme;
    final yesterday = tester.widget<DecoratedBox>(
      find.byKey(const Key('statsBar_5')),
    );
    expect((yesterday.decoration as BoxDecoration).color, scheme.error);
  });

  testWidgets('กดเดือน → 30 แท่ง และนับข้อมูลย้อนหลัง 10 วันด้วย', (
    tester,
  ) async {
    repo.items.addAll([
      entry('a', 1500, 0),
      entry('b', 2500, 1),
      entry('c', 1900, 3),
      entry('d', 2200, 10),
    ]);
    await openStats(tester);

    await tester.tap(find.text('เดือน'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('statsBar_29')), findsOneWidget);
    expect(textOf(tester, 'statsLoggedDays'), '4');
    expect(textOf(tester, 'statsAverage'), '2,025'); // (1500+2500+1900+2200)/4
    expect(textOf(tester, 'statsOverDays'), '2');
  });

  testWidgets('เพิ่มอาหารที่หน้าหลัก แล้วกลับมาหน้าสถิติ → ตัวเลขอัปเดต', (
    tester,
  ) async {
    await openStats(tester);
    expect(textOf(tester, 'statsLoggedDays'), '0');

    await tester.tap(find.byKey(const Key('navHome')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('addMeal_lunch')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('manualFoodButton'))); // หน้าเพิ่มอาหาร → สร้างเอง
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('foodNameField')),
      'ข้าวมันไก่',
    );
    await tester.enterText(find.byKey(const Key('caloriesField')), '300');
    await tester.tap(find.byKey(const Key('saveFoodButton')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('navStats')));
    await tester.pumpAndSettle();

    expect(textOf(tester, 'statsLoggedDays'), '1');
    expect(textOf(tester, 'statsAverage'), '300');
    expect(find.byKey(const Key('statsEmpty')), findsNothing);
  });

  testWidgets('แก้เป้าที่โปรไฟล์ → ป้ายเป้าหมายและแท่งเกินเป้าเปลี่ยนตาม', (
    tester,
  ) async {
    repo.items.add(entry('a', 1500, 0));
    await openStats(tester);
    expect(textOf(tester, 'statsOverDays'), '0');

    // ตั้งเป้าใหม่ 1,000 ผ่านโปรไฟล์ → 1,500 กลายเป็นเกินเป้า
    await tester.tap(find.byKey(const Key('navProfile')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('editGoalButton')));
    await tester.pumpAndSettle();
    tester.widget<Slider>(find.byKey(const Key('goalSlider'))).onChanged!(1000);
    await tester.pump();
    await tester.tap(find.byKey(const Key('saveGoalButton')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('navStats')));
    await tester.pumpAndSettle();

    expect(textOf(tester, 'statsGoalLabel'), 'เป้าหมาย 1,000 kcal');
    expect(textOf(tester, 'statsOverDays'), '1');
  });
}