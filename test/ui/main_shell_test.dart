import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_log/app/app.dart';

import '../helpers/fake_auth_service.dart';
import '../helpers/fake_food_repository.dart';

void main() {
  late FakeAuthService auth;

  setUp(() async {
    auth = FakeAuthService();
    await auth.signIn(
      email: 'min@test.com',
      password: 'foodlog2026',
    ); // ล็อกอินไว้ก่อน
  });

  Future<void> openApp(WidgetTester tester) async {
    await tester.pumpWidget(
      FoodLogApp(auth: auth, repository: FakeFoodRepository()),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapTab(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();
  }

  testWidgets('ล็อกอินแล้ว → เริ่มที่แท็บหน้าหลัก และมีเมนูล่าง 4 แท็บ', (
    tester,
  ) async {
    await openApp(tester);

    expect(find.byKey(const Key('calorieTotal')), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(4));
  });

  testWidgets('กดแต่ละแท็บ → เห็นหน้าที่ถูกต้อง แล้วกลับหน้าหลักได้', (
    tester,
  ) async {
    await openApp(tester);

    await tapTab(tester, 'navLog');
    expect(find.byKey(const Key('logTab')), findsOneWidget);
    expect(find.byKey(const Key('calorieTotal')), findsNothing);

    await tapTab(tester, 'navStats');
    expect(find.byKey(const Key('statsTab')), findsOneWidget);

    await tapTab(tester, 'navProfile');
    expect(find.byKey(const Key('profileTab')), findsOneWidget);

    await tapTab(tester, 'navHome');
    expect(find.byKey(const Key('calorieTotal')), findsOneWidget);
  });

  testWidgets('มีปุ่มสแกนตรงกลาง และกดได้โดยไม่พัง', (tester) async {
    await openApp(tester);

    expect(find.byKey(const Key('scanButton')), findsOneWidget);
    await tester.tap(find.byKey(const Key('scanButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('calorieTotal')), findsOneWidget);
  });
}
