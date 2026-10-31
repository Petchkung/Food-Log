import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_log/ui/widgets/home_header.dart';

void main() {
  Widget build({
    bool syncing = false,
    int pending = 0,
    VoidCallback? onSync,
    VoidCallback? onSignOut,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: HomeHeader(
          day: DateTime(2026, 10, 28),
          name: 'min',
          syncing: syncing,
          pendingCount: pending,
          onSync: onSync ?? () {},
          onSignOut: onSignOut ?? () {},
        ),
      ),
    );
  }

  testWidgets('แสดงวันที่ คำทักทาย และตัวอักษรแรกของชื่อ', (tester) async {
    await tester.pumpWidget(build());

    expect(find.text('พุธ 28 ต.ค.'), findsOneWidget);
    expect(find.text('สวัสดี, min'), findsOneWidget);
    expect(find.text('M'), findsOneWidget);
  });

  testWidgets('ซิงก์แล้ว → กดชิปแล้วเรียก onSync', (tester) async {
    var calls = 0;
    await tester.pumpWidget(build(onSync: () => calls++));

    expect(find.text('ซิงก์แล้ว'), findsOneWidget);
    await tester.tap(find.byKey(const Key('syncButton')));
    expect(calls, 1);
  });

  testWidgets('มีรายการค้างซิงก์ → แสดงจำนวน', (tester) async {
    await tester.pumpWidget(build(pending: 3));
    expect(find.text('รอซิงก์ 3'), findsOneWidget);
  });

  testWidgets('กำลังซิงก์ → กดชิปไม่ได้', (tester) async {
    var calls = 0;
    await tester.pumpWidget(build(syncing: true, onSync: () => calls++));

    expect(find.text('กำลังซิงก์'), findsOneWidget);
    await tester.tap(find.byKey(const Key('syncButton')));
    expect(calls, 0);
  });

  testWidgets('กดปุ่มออกจากระบบ → เรียก onSignOut', (tester) async {
    var calls = 0;
    await tester.pumpWidget(build(onSignOut: () => calls++));

    await tester.tap(find.byKey(const Key('signOutButton')));
    expect(calls, 1);
  });
}
