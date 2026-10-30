import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_log/ui/screens/login_screen.dart';

import '../helpers/fake_auth_service.dart';

void main() {
  late FakeAuthService auth;

  setUp(() => auth = FakeAuthService());

  Future<void> openLogin(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: LoginScreen(auth: auth)));
  }

  Future<void> openForgotDialog(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('forgotPasswordButton')));
    await tester.pumpAndSettle();
  }

  group('ล็อกอินด้วย Google', () {
    testWidgets('กดปุ่ม Google → ล็อกอินสำเร็จ', (tester) async {
      await openLogin(tester);
      await tester.tap(find.byKey(const Key('googleButton')));
      await tester.pumpAndSettle();

      expect(auth.currentUser?.email, 'google.user@gmail.com');
      expect(find.byKey(const Key('authError')), findsNothing);
    });

    testWidgets('ยกเลิกหน้าเลือกบัญชี → แสดงข้อความ ไม่ล็อกอิน', (tester) async {
      auth.failWith = 'web-context-canceled';
      await openLogin(tester);
      await tester.tap(find.byKey(const Key('googleButton')));
      await tester.pumpAndSettle();

      expect(auth.currentUser, isNull);
      expect(find.text('ยกเลิกการเข้าสู่ระบบด้วย Google'), findsOneWidget);
    });
  });

  group('ลืมรหัสผ่าน', () {
    testWidgets('ส่งลิงก์สำเร็จ → ปิดกล่อง และแสดงข้อความยืนยัน', (tester) async {
      await openLogin(tester);
      await openForgotDialog(tester);

      await tester.enterText(find.byKey(const Key('resetEmailField')), 'me@test.com');
      await tester.tap(find.byKey(const Key('sendResetButton')));
      await tester.pumpAndSettle();

      expect(auth.resetEmails, ['me@test.com']);
      expect(find.byKey(const Key('resetEmailField')), findsNothing);
      expect(find.byKey(const Key('resetSentMessage')), findsOneWidget);
    });

    testWidgets('เติมอีเมลจากหน้า login ให้อัตโนมัติ', (tester) async {
      await openLogin(tester);
      await tester.enterText(find.byKey(const Key('emailField')), 'auto@test.com');
      await openForgotDialog(tester);

      await tester.tap(find.byKey(const Key('sendResetButton')));
      await tester.pumpAndSettle();

      expect(auth.resetEmails, ['auto@test.com']);
    });

    testWidgets('อีเมลผิดรูปแบบ → ไม่ส่ง และกล่องยังเปิดอยู่', (tester) async {
      await openLogin(tester);
      await openForgotDialog(tester);

      await tester.enterText(find.byKey(const Key('resetEmailField')), 'not-an-email');
      await tester.tap(find.byKey(const Key('sendResetButton')));
      await tester.pumpAndSettle();

      expect(auth.resetEmails, isEmpty);
      expect(find.byKey(const Key('resetEmailField')), findsOneWidget);
    });

    testWidgets('ส่งไม่สำเร็จ → แสดง error ในกล่อง', (tester) async {
      auth.failWith = 'too-many-requests';
      await openLogin(tester);
      await openForgotDialog(tester);

      await tester.enterText(find.byKey(const Key('resetEmailField')), 'me@test.com');
      await tester.tap(find.byKey(const Key('sendResetButton')));
      await tester.pumpAndSettle();

      expect(find.text('พยายามหลายครั้งเกินไป กรุณารอสักครู่'), findsOneWidget);
      expect(find.byKey(const Key('resetEmailField')), findsOneWidget);
    });

    testWidgets('กดยกเลิก → ปิดกล่อง ไม่ส่งอะไร', (tester) async {
      await openLogin(tester);
      await openForgotDialog(tester);

      await tester.tap(find.text('ยกเลิก'));
      await tester.pumpAndSettle();

      expect(auth.resetEmails, isEmpty);
      expect(find.byKey(const Key('resetSentMessage')), findsNothing);
    });

    testWidgets('โหมดสมัครสมาชิก → ไม่แสดงลิงก์ลืมรหัสผ่าน', (tester) async {
      await openLogin(tester);
      expect(find.byKey(const Key('forgotPasswordButton')), findsOneWidget);

      await tester.tap(find.byKey(const Key('toggleModeButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('forgotPasswordButton')), findsNothing);
    });
  });
}