import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_log/app/app.dart';

import '../helpers/fake_auth_service.dart';
import '../helpers/fake_food_repository.dart';

void main() {
  late FakeAuthService auth;

  setUp(() => auth = FakeAuthService());

  /// ผ่านหน้า Welcome ไปหน้า Login
  Future<void> goToLogin(WidgetTester tester) async {
    final start = find.byKey(const Key('welcomeLoginButton'));
    await tester.ensureVisible(start);
    await tester.tap(start);
    await tester.pumpAndSettle();
  }

  Future<void> openApp(WidgetTester tester) async {
    await tester.pumpWidget(
      FoodLogApp(auth: auth, repository: FakeFoodRepository()),
    );
    await goToLogin(tester);
  }

  Future<void> fillAndSubmit(
    WidgetTester tester,
    String email,
    String password,
  ) async {
    await tester.enterText(find.byKey(const Key('emailField')), email);
    await tester.enterText(find.byKey(const Key('passwordField')), password);
    await tester.tap(find.byKey(const Key('submitButton')));
    await tester.pumpAndSettle();
  }

  testWidgets('กดเข้าสู่ระบบโดยไม่กรอก → แสดงข้อความเตือน', (tester) async {
    await openApp(tester);
    await tester.tap(find.byKey(const Key('submitButton')));
    await tester.pumpAndSettle();

    expect(find.text('กรุณากรอกอีเมล'), findsOneWidget);
    expect(find.text('กรุณากรอกรหัสผ่าน'), findsOneWidget);
  });

  testWidgets('เข้าสู่ระบบสำเร็จ → ไปหน้าหลัก แล้วออกจากระบบได้', (
    tester,
  ) async {
    await openApp(tester);
    await fillAndSubmit(tester, 'student@kmitl.ac.th', 'foodlog2026');

    expect(find.text('สวัสดี, student'), findsOneWidget);

    await tester.tap(find.byKey(const Key('signOutButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('welcomeStartButton')), findsOneWidget);
    await goToLogin(tester);
    expect(find.byKey(const Key('emailField')), findsOneWidget);
  });

  testWidgets('รหัสผ่านผิด → แสดงข้อความ error ภาษาไทย', (tester) async {
    auth.failWith = 'invalid-credential';
    await openApp(tester);
    await fillAndSubmit(tester, 'student@kmitl.ac.th', 'wrongpass1');

    expect(find.byKey(const Key('authError')), findsOneWidget);
    expect(find.text('อีเมลหรือรหัสผ่านไม่ถูกต้อง'), findsOneWidget);
  });

  testWidgets('โหมดสมัคร → บังคับรหัสผ่านแข็งแรง', (tester) async {
    await openApp(tester);
    await tester.tap(find.byKey(const Key('toggleModeButton')));
    await tester.pumpAndSettle();

    await fillAndSubmit(tester, 'new@kmitl.ac.th', 'abc');
    expect(find.textContaining('อย่างน้อย 8'), findsOneWidget);
    expect(auth.currentUser, isNull);
  });
}
