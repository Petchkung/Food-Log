import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_log/app/app.dart';

import '../helpers/fake_auth_service.dart';
import '../helpers/fake_food_repository.dart';

void main() {
  late FakeAuthService auth;
  late FakeFoodRepository repo;

  setUp(() async {
    auth = FakeAuthService();
    repo = FakeFoodRepository();
    await auth.signIn(email: 'min@test.com', password: 'foodlog2026');
  });

  Future<void> openProfile(WidgetTester tester) async {
    tester.view.physicalSize = const Size(500, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(FoodLogApp(auth: auth, repository: repo));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('navProfile')));
    await tester.pumpAndSettle();
  }

  String textOf(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(Key(key))).data!;

  /// ตั้งค่า Slider ในกล่องเป้าหมาย (ลากจริงในเทสต์ทำยาก จึงเรียก onChanged ตรง ๆ)
  Future<void> pickGoal(WidgetTester tester, double value) async {
    tester.widget<Slider>(find.byKey(const Key('goalSlider'))).onChanged!(
      value,
    );
    await tester.pump();
  }

  testWidgets('แสดงชื่อ อีเมล และเป้าหมายเริ่มต้น', (tester) async {
    await openProfile(tester);

    expect(textOf(tester, 'profileName'), 'min');
    expect(textOf(tester, 'profileEmail'), 'min@test.com');
    expect(textOf(tester, 'profileGoal'), '2,000');
    expect(textOf(tester, 'profileProtein'), '100');
    expect(textOf(tester, 'profileCarbs'), '250');
    expect(textOf(tester, 'profileFat'), '67');
    // ปุ่มออกจากระบบย้ายมาที่นี่แล้ว ไม่อยู่ในหน้าหลักอีก
    expect(find.byKey(const Key('signOutButton')), findsNothing);
  });

  testWidgets('แก้เป้าแคลอรี่ → โปรไฟล์ หน้าหลัก และ repository ได้ค่าใหม่', (
    tester,
  ) async {
    await openProfile(tester);

    await tester.tap(find.byKey(const Key('editGoalButton')));
    await tester.pumpAndSettle();
    expect(textOf(tester, 'goalValueText'), '2,000 kcal');

    await pickGoal(tester, 1800);
    expect(textOf(tester, 'goalValueText'), '1,800 kcal');
    await tester.tap(find.byKey(const Key('saveGoalButton')));
    await tester.pumpAndSettle();

    expect(textOf(tester, 'profileGoal'), '1,800');
    expect(textOf(tester, 'profileProtein'), '90');
    expect(repo.goal, 1800);

    await tester.tap(find.byKey(const Key('navHome')));
    await tester.pumpAndSettle();
    expect(find.text('จาก 1,800 kcal'), findsOneWidget);
  });

  testWidgets('กดยกเลิกในกล่องเป้าหมาย → ค่าไม่เปลี่ยน', (tester) async {
    await openProfile(tester);

    await tester.tap(find.byKey(const Key('editGoalButton')));
    await tester.pumpAndSettle();
    await pickGoal(tester, 1000);
    await tester.tap(find.text('ยกเลิก'));
    await tester.pumpAndSettle();

    expect(textOf(tester, 'profileGoal'), '2,000');
    expect(repo.goal, 2000);
  });

  testWidgets('กดซิงก์ → เรียก sync ที่ repository', (tester) async {
    await openProfile(tester);
    final before = repo.syncCalls;

    await tester.tap(find.byKey(const Key('profileSyncButton')));
    await tester.pumpAndSettle();

    expect(repo.syncCalls, before + 1);
  });

  testWidgets('กดออกจากระบบ → กลับหน้า Welcome', (tester) async {
    await openProfile(tester);

    await tester.tap(find.byKey(const Key('profileSignOutButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('welcomeStartButton')), findsOneWidget);
    expect(auth.currentUser, isNull);
  });
}
