import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_log/app/app.dart';

import 'helpers/fake_auth_service.dart';
import 'helpers/fake_food_repository.dart';

void main() {
  testWidgets('ยังไม่ล็อกอิน → เห็นหน้า Welcome และใช้ Material 3', (
    tester,
  ) async {
    await tester.pumpWidget(
      FoodLogApp(auth: FakeAuthService(), repository: FakeFoodRepository()),
    );

    expect(find.byKey(const Key('welcomeStartButton')), findsOneWidget);
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme!.useMaterial3, isTrue);
  });
}
