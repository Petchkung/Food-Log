import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_log/app/app.dart';
import 'package:food_log/core/thai_format.dart';
import 'package:food_log/models/food_entry.dart';
import 'package:food_log/models/meal_type.dart';
import 'package:food_log/ui/widgets/home_header.dart';

import '../helpers/fake_auth_service.dart';
import '../helpers/fake_food_repository.dart';

void main() {
  group('HomeHeader ลูกศรเปลี่ยนวัน', () {
    Widget wrap({VoidCallback? onPrev, VoidCallback? onNext}) => MaterialApp(
      home: Scaffold(
        body: HomeHeader(
          day: DateTime(2026, 10, 28),
          name: 'min',
          syncing: false,
          pendingCount: 0,
          onSync: () {},
          onSignOut: () {},
          onPreviousDay: onPrev,
          onNextDay: onNext,
        ),
      ),
    );

    testWidgets('ไม่ส่ง onPreviousDay → ไม่แสดงลูกศร', (tester) async {
      await tester.pumpWidget(wrap());

      expect(find.byKey(const Key('prevDayButton')), findsNothing);
      expect(find.byKey(const Key('nextDayButton')), findsNothing);
    });

    testWidgets('กดลูกศร → เรียก callback ของวันก่อนหน้า/ถัดไป', (
      tester,
    ) async {
      var prev = 0;
      var next = 0;
      await tester.pumpWidget(wrap(onPrev: () => prev++, onNext: () => next++));

      await tester.tap(find.byKey(const Key('prevDayButton')));
      await tester.tap(find.byKey(const Key('nextDayButton')));

      expect(prev, 1);
      expect(next, 1);
    });

    testWidgets('onNextDay เป็น null → ลูกศรขวากดไม่ได้', (tester) async {
      await tester.pumpWidget(wrap(onPrev: () {}));

      final next = tester.widget<IconButton>(
        find.byKey(const Key('nextDayButton')),
      );
      expect(next.onPressed, isNull);
    });
  });

  group('หน้าหลัก เปลี่ยนวัน', () {
    late FakeAuthService auth;
    late FakeFoodRepository repo;

    setUp(() async {
      auth = FakeAuthService();
      repo = FakeFoodRepository();
      await auth.signIn(email: 'min@test.com', password: 'foodlog2026');
    });

    Future<void> openApp(WidgetTester tester) async {
      tester.view.physicalSize = const Size(500, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(FoodLogApp(auth: auth, repository: repo));
      await tester.pumpAndSettle();
    }

    testWidgets('วันนี้ → ลูกศรขวากดไม่ได้', (tester) async {
      await openApp(tester);

      final next = tester.widget<IconButton>(
        find.byKey(const Key('nextDayButton')),
      );
      expect(next.onPressed, isNull);
      expect(find.text('มื้ออาหารวันนี้'), findsOneWidget);
    });

    testWidgets(
      'กดวันก่อนหน้า → เห็นข้อมูลเมื่อวาน แล้วกดวันถัดไปกลับมาวันนี้',
      (tester) async {
        final now = DateTime.now();
        final yesterday = DateTime(now.year, now.month, now.day - 1);
        repo.items.add(
          FoodEntry(
            id: 'y1',
            userId: 'test-uid',
            name: 'ข้าวต้ม',
            calories: 250,
            mealType: MealType.breakfast,
            eatenAt: DateTime(
              yesterday.year,
              yesterday.month,
              yesterday.day,
              8,
            ),
          ),
        );
        await openApp(tester);
        expect(find.text('ข้าวต้ม'), findsNothing); // วันนี้ยังไม่มี

        await tester.tap(find.byKey(const Key('prevDayButton')));
        await tester.pumpAndSettle();

        expect(find.text(ThaiFormat.date(yesterday)), findsOneWidget);
        expect(find.text('ข้าวต้ม'), findsOneWidget);
        expect(find.text('มื้ออาหาร'), findsOneWidget); // ไม่ใช่ "วันนี้"
        expect(find.text('มื้ออาหารวันนี้'), findsNothing);

        await tester.tap(find.byKey(const Key('nextDayButton')));
        await tester.pumpAndSettle();

        expect(find.text('ข้าวต้ม'), findsNothing);
        expect(find.text(ThaiFormat.date(now)), findsOneWidget);
        expect(find.text('มื้ออาหารวันนี้'), findsOneWidget);
      },
    );
  });
}
