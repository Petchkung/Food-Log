import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_log/models/food_entry.dart';
import 'package:food_log/models/meal_type.dart';
import 'package:food_log/models/nutrition_info.dart';
import 'package:food_log/services/food_api_service.dart';
import 'package:food_log/state/food_log_controller.dart';
import 'package:food_log/ui/screens/add_food_screen.dart';
import 'package:provider/provider.dart';

import '../helpers/fake_food_api_service.dart';
import '../helpers/fake_food_repository.dart';

void main() {
  late FakeFoodRepository repo;
  late FakeFoodApiService api;
  late FoodLogController controller;

  setUp(() {
    repo = FakeFoodRepository();
    api = FakeFoodApiService(
      results: [
        NutritionInfo(
          name: 'ข้าวมันไก่',
          brand: 'ร้านป้า',
          calories: 180,
          protein: 8,
          carbs: 25,
          fat: 5,
        ),
      ],
    );
    // ล็อกเวลาเป็นเที่ยงวัน → มื้อที่เดาให้คือมื้อกลางวัน
    controller = FoodLogController(
      repository: repo,
      uid: 'test-uid',
      clock: () => DateTime(2026, 11, 3, 12),
    );
  });

  Future<void> open(WidgetTester tester, {MealType? meal}) async {
    tester.view.physicalSize = const Size(500, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<FoodApiService>.value(value: api),
          ChangeNotifierProvider<FoodLogController>.value(value: controller),
        ],
        child: MaterialApp(home: AddFoodScreen(initialMeal: meal)),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> search(WidgetTester tester, String query) async {
    await tester.enterText(find.byKey(const Key('foodSearchBar')), query);
    await tester.tap(find.byKey(const Key('searchButton')));
    await tester.pumpAndSettle();
  }

  group('ค้นหาจาก Open Food Facts', () {
    testWidgets('ค้นแล้วเห็นผล พร้อมยี่ห้อและแคลอรี่ต่อ 100 g', (tester) async {
      await open(tester);
      await search(tester, 'ข้าวมันไก่');

      expect(api.queries, ['ข้าวมันไก่']);
      // หาในรายการผล (ไม่นับข้อความในช่องค้นหา)
      expect(find.widgetWithText(ListTile, 'ข้าวมันไก่'), findsOneWidget);
      expect(find.text('ร้านป้า · 180 kcal / 100 g'), findsOneWidget);
    });

    testWidgets('เลือกผล → ปรับเป็น 200 g + มื้อเย็น → บันทึกพร้อมสารอาหาร', (
      tester,
    ) async {
      await open(tester);
      await search(tester, 'ข้าวมันไก่');

      await tester.tap(find.byKey(const ValueKey('result-0')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('portionSheet')), findsOneWidget);
      expect(find.text('180 kcal'), findsOneWidget); // ค่าเริ่มต้น 100 g

      await tester.enterText(find.byKey(const Key('gramsField')), '200');
      await tester.pumpAndSettle();
      expect(find.text('360 kcal'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'มื้อเย็น'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmAddButton')));
      await tester.pumpAndSettle();

      final saved = repo.items.single;
      expect(saved.name, 'ข้าวมันไก่');
      expect(saved.calories, 360);
      expect(saved.protein, 16);
      expect(saved.carbs, 50);
      expect(saved.fat, 10);
      expect(saved.mealType, MealType.dinner);
      expect(find.byKey(const Key('portionSheet')), findsNothing);
    });

    testWidgets('ปริมาณไม่ถูกต้อง → ปุ่มเพิ่มกดไม่ได้', (tester) async {
      await open(tester);
      await search(tester, 'ข้าวมันไก่');
      await tester.tap(find.byKey(const ValueKey('result-0')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('gramsField')), '0');
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(
        find.byKey(const Key('confirmAddButton')),
      );
      expect(button.onPressed, isNull);
      expect(find.text('กรอกตัวเลข 1–5000'), findsOneWidget);
    });

    testWidgets('ค้นไม่เจอ → แสดงข้อความแนะนำ', (tester) async {
      await open(tester);
      await search(tester, 'พิซซ่า');

      expect(find.byKey(const Key('noResults')), findsOneWidget);
    });

    testWidgets('คำค้นสั้นกว่า 2 ตัว → แจ้งเตือน และไม่เรียก API', (tester) async {
      await open(tester);
      await search(tester, 'ก');

      expect(api.queries, isEmpty);
      expect(find.text('พิมพ์ชื่ออาหารอย่างน้อย 2 ตัวอักษร'), findsOneWidget);
    });

    testWidgets('API error → แสดงข้อความไทย', (tester) async {
      api.error = const FoodApiException('เชื่อมต่ออินเทอร์เน็ตไม่ได้');
      await open(tester);
      await search(tester, 'ข้าวมันไก่');

      expect(find.byKey(const Key('searchError')), findsOneWidget);
      expect(find.text('เชื่อมต่ออินเทอร์เน็ตไม่ได้'), findsOneWidget);
    });

    testWidgets('ลบคำค้นจนว่าง → ผลค้นหาหายไป', (tester) async {
      await open(tester);
      await search(tester, 'ข้าวมันไก่');
      expect(find.byKey(const ValueKey('result-0')), findsOneWidget);

      await tester.enterText(find.byKey(const Key('foodSearchBar')), '');
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('result-0')), findsNothing);
    });
  });

  group('รายการล่าสุด', () {
    testWidgets('ยังไม่เคยบันทึก → แสดงข้อความว่าง', (tester) async {
      await open(tester);

      expect(find.byKey(const Key('recentEmpty')), findsOneWidget);
    });

    testWidgets('กดรายการล่าสุด → เพิ่มซ้ำได้ทันที (มื้อเดาจากเวลา)', (
      tester,
    ) async {
      repo.items.add(
        FoodEntry(
          id: 'e1',
          userId: 'test-uid',
          name: 'ส้มตำ',
          calories: 120,
          mealType: MealType.breakfast,
          eatenAt: DateTime(2026, 11, 3, 9),
        ),
      );
      await open(tester);

      await tester.tap(find.byKey(const ValueKey('recent-e1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('gramsField')), findsNothing); // ไม่ต้องปรับกรัม

      await tester.tap(find.byKey(const Key('confirmAddButton')));
      await tester.pumpAndSettle();

      expect(repo.items, hasLength(2));
      final added = repo.items.firstWhere((e) => e.id != 'e1');
      expect(added.name, 'ส้มตำ');
      expect(added.calories, 120);
      expect(added.mealType, MealType.lunch); // 12:00 → มื้อกลางวัน
    });

    testWidgets('ปิดชิป "ล่าสุด" → ซ่อนรายการล่าสุด', (tester) async {
      await open(tester);
      expect(find.byKey(const Key('recentEmpty')), findsOneWidget);

      await tester.tap(find.byKey(const Key('recentChip')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('recentEmpty')), findsNothing);
    });
  });

  group('สร้างอาหารเอง', () {
    Future<void> openManual(WidgetTester tester, {MealType? meal}) async {
      await open(tester, meal: meal);
      await tester.tap(find.byKey(const Key('manualFoodButton')));
      await tester.pumpAndSettle();
    }

    testWidgets('กรอกครบ → บันทึกพร้อมสารอาหาร ลงมื้อที่ส่งมา', (tester) async {
      await openManual(tester, meal: MealType.dinner);

      await tester.enterText(find.byKey(const Key('foodNameField')), 'ผัดไทย');
      await tester.enterText(find.byKey(const Key('caloriesField')), '450');
      await tester.enterText(find.byKey(const Key('proteinField')), '15');
      await tester.enterText(find.byKey(const Key('fatField')), '12.5');
      await tester.tap(find.byKey(const Key('saveFoodButton')));
      await tester.pumpAndSettle();

      final saved = repo.items.single;
      expect(saved.name, 'ผัดไทย');
      expect(saved.calories, 450);
      expect(saved.protein, 15);
      expect(saved.carbs, 0); // เว้นว่าง = 0
      expect(saved.fat, 12.5);
      expect(saved.mealType, MealType.dinner);
      expect(find.byKey(const Key('foodNameField')), findsNothing); // กลับหน้าเดิม
    });

    testWidgets('ไม่ส่งมื้อมา → เลือกมื้อตามเวลาไว้ให้', (tester) async {
      await openManual(tester);

      final lunch = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'มื้อกลางวัน'),
      );
      expect(lunch.selected, isTrue);
    });

    testWidgets('กรอกผิด → แจ้งเตือนทุกช่อง และไม่บันทึก', (tester) async {
      await openManual(tester);

      await tester.enterText(find.byKey(const Key('caloriesField')), '6000');
      await tester.enterText(find.byKey(const Key('proteinField')), 'abc');
      await tester.enterText(find.byKey(const Key('fatField')), '2000');
      await tester.tap(find.byKey(const Key('saveFoodButton')));
      await tester.pumpAndSettle();

      expect(find.text('กรุณากรอกชื่ออาหาร'), findsOneWidget);
      expect(find.text('ต้องอยู่ระหว่าง 0–5000'), findsOneWidget);
      expect(find.text('กรุณากรอกเป็นตัวเลข'), findsOneWidget);
      expect(find.text('ต้องอยู่ระหว่าง 0–1000'), findsOneWidget);
      expect(repo.items, isEmpty);
    });
  });
}
