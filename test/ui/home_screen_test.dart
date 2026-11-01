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
    // จอสูง ให้เห็นการ์ดทั้ง 4 มื้อโดยไม่ต้องเลื่อน
    tester.view.physicalSize = const Size(500, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(FoodLogApp(auth: auth, repository: repo));
    await tester.pumpAndSettle();
  }

  /// ตัวเลขแคลอรี่รวมกลางวงแหวน เช่น "520"
  String totalText(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('calorieTotal'))).data!;

  /// ข้อความหัวการ์ดมื้อ เช่น "มื้อกลางวัน · 520 kcal"
  String mealTitle(WidgetTester tester, MealType meal) => tester
      .widget<Text>(find.byKey(Key('mealTitle_${meal.name}')))
      .textSpan!
      .toPlainText();

  Future<void> addViaDialog(
    WidgetTester tester,
    String name,
    String kcal,
  ) async {
    await tester.enterText(find.byKey(const Key('foodNameField')), name);
    await tester.enterText(find.byKey(const Key('caloriesField')), kcal);
    await tester.tap(find.byKey(const Key('saveFoodButton')));
    await tester.pumpAndSettle();
  }

  FoodEntry entry(String id, String name, double kcal, MealType meal) =>
      FoodEntry(
        id: id,
        userId: 'test-uid',
        name: name,
        calories: kcal,
        mealType: meal,
        eatenAt: DateTime.now(),
      );

  testWidgets(
    'ยังไม่มีรายการ → ข้อความว่าง 0 จาก 2,000 kcal และการ์ดครบ 4 มื้อ',
    (tester) async {
      await openApp(tester);

      expect(find.byKey(const Key('emptyState')), findsOneWidget);
      expect(totalText(tester), '0');
      expect(find.text('จาก 2,000 kcal'), findsOneWidget);
      for (final meal in MealType.values) {
        expect(mealTitle(tester, meal), meal.label);
      }
      expect(find.text('ยังไม่มีรายการ'), findsNWidgets(4));
    },
  );

  testWidgets(
    'กด + ที่มื้อกลางวัน → เลือกมื้อกลางวันไว้ให้ และบันทึกลงมื้อนั้น',
    (tester) async {
      await openApp(tester);

      await tester.tap(find.byKey(const Key('addMeal_lunch')));
      await tester.pumpAndSettle();
      final lunchChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'มื้อกลางวัน'),
      );
      expect(lunchChip.selected, isTrue);

      await addViaDialog(tester, 'ข้าวมันไก่', '520');

      expect(find.text('ข้าวมันไก่'), findsOneWidget);
      expect(totalText(tester), '520');
      expect(mealTitle(tester, MealType.lunch), 'มื้อกลางวัน · 520 kcal');
      expect(
        mealTitle(tester, MealType.breakfast),
        'มื้อเช้า',
      ); // มื้ออื่นยังว่าง
      expect(repo.items.single.mealType, MealType.lunch);
    },
  );

  testWidgets(
    'เปิดจากมื้อเช้า แล้วเปลี่ยนเป็นมื้อเย็นในกล่อง → บันทึกเป็นมื้อเย็น',
    (tester) async {
      await openApp(tester);

      await tester.tap(find.byKey(const Key('addMeal_breakfast')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'มื้อเย็น'));
      await addViaDialog(tester, 'ต้มยำกุ้ง', '300');

      expect(repo.items.single.mealType, MealType.dinner);
      expect(mealTitle(tester, MealType.dinner), 'มื้อเย็น · 300 kcal');
    },
  );

  testWidgets('กล่องเพิ่มอาหาร: ไม่กรอก → แจ้งเตือน และไม่บันทึก', (
    tester,
  ) async {
    await openApp(tester);

    await tester.tap(find.byKey(const Key('addMeal_lunch')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('caloriesField')), 'abc');
    await tester.tap(find.byKey(const Key('saveFoodButton')));
    await tester.pumpAndSettle();

    expect(find.text('กรุณากรอกชื่ออาหาร'), findsOneWidget);
    expect(find.text('กรุณากรอกเป็นตัวเลข'), findsOneWidget);
    expect(repo.items, isEmpty);
  });

  testWidgets('การ์ดแต่ละมื้อแสดงแคลอรี่รวมและรายการของมื้อนั้น', (
    tester,
  ) async {
    repo.items.addAll([
      entry('e1', 'โจ๊กหมู', 300, MealType.breakfast),
      entry('e2', 'ไข่ต้ม', 120, MealType.breakfast),
      entry('e3', 'ข้าวมันไก่', 520, MealType.lunch),
    ]);
    await openApp(tester);

    expect(mealTitle(tester, MealType.breakfast), 'มื้อเช้า · 420 kcal');
    expect(mealTitle(tester, MealType.lunch), 'มื้อกลางวัน · 520 kcal');
    expect(mealTitle(tester, MealType.dinner), 'มื้อเย็น');
    expect(find.text('โจ๊กหมู'), findsOneWidget);
    expect(find.text('ไข่ต้ม'), findsOneWidget);
    expect(find.text('ข้าวมันไก่'), findsOneWidget);
    expect(totalText(tester), '940');
    expect(find.byKey(const Key('emptyState')), findsNothing);
  });

  testWidgets('กดลบ → รายการหายไป', (tester) async {
    repo.items.add(entry('e1', 'ส้มตำ', 120, MealType.lunch));
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
