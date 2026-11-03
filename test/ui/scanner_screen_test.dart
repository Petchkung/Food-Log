import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_log/models/meal_type.dart';
import 'package:food_log/models/nutrition_info.dart';
import 'package:food_log/services/ai_food_analyzer.dart';
import 'package:food_log/services/photo_picker.dart';
import 'package:food_log/state/food_log_controller.dart';
import 'package:food_log/ui/screens/scanner_screen.dart';
import 'package:provider/provider.dart';

import '../helpers/fake_ai_food_analyzer.dart';
import '../helpers/fake_food_repository.dart';
import '../helpers/fake_photo_picker.dart';

/// AI ที่รอให้เทสต์สั่งก่อนถึงจะตอบ (ไว้ดูหน้าจอระหว่างกำลังวิเคราะห์)
class _SlowAi extends FakeAiFoodAnalyzer {
  final gate = Completer<void>();

  @override
  Future<NutritionInfo> analyzeText(String description) async {
    await gate.future;
    return super.analyzeText(description);
  }
}

void main() {
  late FakeFoodRepository repo;
  late FakeAiFoodAnalyzer ai;
  late FakePhotoPicker picker;
  late FoodLogController controller;

  setUp(() {
    repo = FakeFoodRepository();
    ai = FakeAiFoodAnalyzer(); // ตอบ "ข้าวมันไก่ 520 kcal / 300 g มั่นใจ 86%"
    picker = FakePhotoPicker();
    controller = FoodLogController(
      repository: repo,
      uid: 'test-uid',
      clock: () => DateTime(2026, 11, 3, 12), // เที่ยง → มื้อกลางวัน
    );
  });

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(500, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AiFoodAnalyzer>.value(value: ai),
          Provider<PhotoPicker>.value(value: picker),
          ChangeNotifierProvider<FoodLogController>.value(value: controller),
        ],
        child: const MaterialApp(home: ScannerScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();
  }

  group('หน้าสแกน', () {
    testWidgets('เลือกรูปจากแกลเลอรี → AI วิเคราะห์ → เปิดหน้าผล', (tester) async {
      await open(tester);
      await tapKey(tester, 'galleryButton');

      expect(picker.calls, [PhotoSource.gallery]);
      expect(ai.imageCalls, 1);
      expect(find.byKey(const Key('scanResultScreen')), findsOneWidget);
      expect(find.text('ข้าวมันไก่'), findsOneWidget);
      expect(find.text('520 kcal'), findsOneWidget);
      expect(find.text('86%'), findsOneWidget);
    });

    testWidgets('ถ่ายรูปแล้วกดยกเลิก → ไม่เรียก AI และอยู่หน้าเดิม', (tester) async {
      picker.photo = null;
      await open(tester);
      await tapKey(tester, 'cameraButton');

      expect(picker.calls, [PhotoSource.camera]);
      expect(ai.imageCalls, 0);
      expect(find.byKey(const Key('scanResultScreen')), findsNothing);
      expect(find.byKey(const Key('scanError')), findsNothing);
    });

    testWidgets('เปิดกล้องไม่ได้ (ไม่ให้สิทธิ์) → แสดงข้อความไทย', (tester) async {
      picker.error = Exception('permission denied');
      await open(tester);
      await tapKey(tester, 'cameraButton');

      expect(find.byKey(const Key('scanError')), findsOneWidget);
      expect(ai.imageCalls, 0);
    });

    testWidgets('AI error → แสดงข้อความ และไม่เปิดหน้าผล', (tester) async {
      ai.error = const AiAnalysisException('รูปนี้ไม่ใช่อาหาร ลองถ่ายใหม่');
      await open(tester);
      await tapKey(tester, 'galleryButton');

      expect(find.text('รูปนี้ไม่ใช่อาหาร ลองถ่ายใหม่'), findsOneWidget);
      expect(find.byKey(const Key('scanResultScreen')), findsNothing);
    });

    testWidgets('บรรยายเป็นข้อความ → ส่งข้อความให้ AI แล้วเปิดหน้าผล', (tester) async {
      await open(tester);
      await tester.enterText(
        find.byKey(const Key('describeField')),
        'ข้าวผัดกุ้ง 1 จาน',
      );
      await tapKey(tester, 'textAnalyzeButton');

      expect(ai.texts, ['ข้าวผัดกุ้ง 1 จาน']);
      expect(find.byKey(const Key('scanResultScreen')), findsOneWidget);
    });

    testWidgets('กดวิเคราะห์โดยไม่พิมพ์อะไร → แจ้งเตือน และไม่เรียก AI', (tester) async {
      await open(tester);
      await tapKey(tester, 'textAnalyzeButton');

      expect(find.byKey(const Key('scanError')), findsOneWidget);
      expect(ai.texts, isEmpty);
    });

    testWidgets('ระหว่างรอ AI → แสดงสถานะกำลังวิเคราะห์', (tester) async {
      final slow = _SlowAi();
      ai = slow;
      await open(tester);
      await tester.enterText(find.byKey(const Key('describeField')), 'ส้มตำ');
      await tester.tap(find.byKey(const Key('textAnalyzeButton')));
      await tester.pump();

      expect(find.byKey(const Key('analyzingIndicator')), findsOneWidget);

      slow.gate.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('scanResultScreen')), findsOneWidget);
    });
  });

  group('หน้าผลสแกน', () {
    Future<void> openResult(WidgetTester tester) async {
      await open(tester);
      await tapKey(tester, 'galleryButton');
    }

    testWidgets('ปรับเป็น 600 g + มื้อเย็น → บันทึกค่าตามสัดส่วน แล้วกลับหน้าแรก', (
      tester,
    ) async {
      await openResult(tester);

      await tester.enterText(find.byKey(const Key('gramsField')), '600');
      await tester.pumpAndSettle();
      expect(find.text('1040 kcal'), findsOneWidget); // 300 g → 600 g = x2

      await tester.tap(find.widgetWithText(ChoiceChip, 'มื้อเย็น'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'addScanButton');

      final saved = repo.items.single;
      expect(saved.name, 'ข้าวมันไก่');
      expect(saved.calories, 1040);
      expect(saved.protein, 56);
      expect(saved.mealType, MealType.dinner);
      expect(find.byKey(const Key('scanResultScreen')), findsNothing);
    });

    testWidgets('ไม่เปลี่ยนอะไร → บันทึกลงมื้อที่เดาจากเวลา', (tester) async {
      await openResult(tester);
      await tapKey(tester, 'addScanButton');

      expect(repo.items.single.calories, 520);
      expect(repo.items.single.mealType, MealType.lunch);
    });

    testWidgets('ปริมาณไม่ถูกต้อง → ปุ่มเพิ่มกดไม่ได้', (tester) async {
      await openResult(tester);
      await tester.enterText(find.byKey(const Key('gramsField')), 'abc');
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(
        find.byKey(const Key('addScanButton')),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('AI ไม่ค่อยมั่นใจ → แสดงคำเตือน', (tester) async {
      ai.result = NutritionInfo(name: 'แกงอะไรสักอย่าง', calories: 300, confidence: 0.3);
      await openResult(tester);

      expect(find.byKey(const Key('lowConfidenceWarning')), findsOneWidget);
      expect(find.text('30%'), findsOneWidget);
    });

    testWidgets('มั่นใจสูง → ไม่มีคำเตือน', (tester) async {
      await openResult(tester);

      expect(find.byKey(const Key('lowConfidenceWarning')), findsNothing);
    });

    testWidgets('"ไม่ใช่รายการนี้? แก้ไขเอง" → ฟอร์มกรอกค่าจาก AI ไว้ให้ แก้แล้วบันทึก', (
      tester,
    ) async {
      await openResult(tester);
      await tapKey(tester, 'editManualButton');

      // ฟอร์มเติมค่าจาก AI ไว้ให้แล้ว
      expect(find.widgetWithText(TextFormField, 'ข้าวมันไก่'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '520'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('caloriesField')), '480');
      await tapKey(tester, 'saveFoodButton');

      final saved = repo.items.single;
      expect(saved.calories, 480);
      expect(saved.protein, 28); // ค่าอื่นจาก AI ยังอยู่
      expect(find.byKey(const Key('scannerScreen')), findsOneWidget); // กลับหน้าแรก
    });
  });
}
