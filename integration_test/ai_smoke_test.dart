import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_log/app/app_check.dart';
import 'package:food_log/firebase_options.dart';
import 'package:food_log/services/gemini_food_analyzer.dart';
import 'package:integration_test/integration_test.dart';

/// เรียก Gemini จริง (ต้องมีเน็ต + debug token):
/// flutter test integration_test/ai_smoke_test.dart --dart-define=APP_CHECK_DEBUG_TOKEN=xxxx
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gemini วิเคราะห์คำบรรยายอาหารไทยได้จริง', (tester) async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await activateAppCheck();

    final info = await GeminiFoodAnalyzer().analyzeText('ข้าวมันไก่ 1 จาน');
    tester.printToConsole('AI ตอบ: ${info.name} ${info.calories} kcal '
        '(P ${info.protein} / C ${info.carbs} / F ${info.fat}) มั่นใจ ${info.confidence}');

    expect(info.name, isNotEmpty);
    expect(info.calories, inInclusiveRange(200, 1500));
  }, skip: appCheckDebugToken.isEmpty);
}