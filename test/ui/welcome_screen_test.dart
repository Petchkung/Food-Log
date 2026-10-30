import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_log/app/app.dart';

import '../helpers/fake_auth_service.dart';
import '../helpers/fake_food_repository.dart';

void main() {
  Future<void> openApp(WidgetTester tester) => tester.pumpWidget(
    FoodLogApp(auth: FakeAuthService(), repository: FakeFoodRepository()),
  );

  Future<void> tapKey(WidgetTester tester, String key) async {
    final finder = find.byKey(Key(key));
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('เปิดแอปครั้งแรก → เห็นหน้า Welcome ก่อนหน้า Login', (
    tester,
  ) async {
    await openApp(tester);

    expect(find.byKey(const Key('welcomeTitle')), findsOneWidget);
    expect(find.text('เริ่มต้นใช้งาน'), findsOneWidget);
    expect(find.text('มีบัญชีแล้ว? เข้าสู่ระบบ'), findsOneWidget);
    expect(find.byKey(const Key('emailField')), findsNothing);
  });

  testWidgets('กดเริ่มต้นใช้งาน → หน้าสมัครสมาชิก แล้วกดกลับได้', (
    tester,
  ) async {
    await openApp(tester);

    await tapKey(tester, 'welcomeStartButton');
    expect(find.byKey(const Key('emailField')), findsOneWidget);
    expect(find.text('สมัครสมาชิก'), findsWidgets); // หัวข้อ + ปุ่มส่ง

    await tester.tap(find.byKey(const Key('loginBackButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('welcomeStartButton')), findsOneWidget);
  });

  testWidgets('กดมีบัญชีแล้ว? เข้าสู่ระบบ → หน้าเข้าสู่ระบบ', (tester) async {
    await openApp(tester);

    await tapKey(tester, 'welcomeLoginButton');
    expect(find.byKey(const Key('emailField')), findsOneWidget);
    expect(find.text('เข้าสู่ระบบ'), findsWidgets); // หัวข้อ + ปุ่มส่ง
    expect(find.text('สมัครสมาชิก'), findsNothing);
  });
}
