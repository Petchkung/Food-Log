import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_log/main.dart';

void main() {
  testWidgets('แอปเปิดได้และใช้ Material 3', (tester) async {
    await tester.pumpWidget(const FoodLogApp());

    expect(find.text('Food Log'), findsOneWidget);

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme!.useMaterial3, isTrue);
  });
}