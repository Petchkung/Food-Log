import 'dart:async';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

import '../models/nutrition_info.dart';
import 'ai_food_analyzer.dart';

/// Gemini ผ่าน Firebase AI Logic — ไม่ต้องฝัง API key ในแอป และป้องกันด้วย App Check
class GeminiFoodAnalyzer implements AiFoodAnalyzer {
  GeminiFoodAnalyzer({String model = defaultModel, this.timeout = const Duration(seconds: 40)})
      : _model = FirebaseAI.googleAI().generativeModel(
          model: model,
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json', // บังคับให้ตอบเป็น JSON
            temperature: 0.2, // ตอบคงที่ ไม่สุ่มมาก
          ),
        );

  /// เปลี่ยนรุ่นได้ตอนรัน: --dart-define=GEMINI_MODEL=...
  static const defaultModel =
      String.fromEnvironment('GEMINI_MODEL', defaultValue: 'gemini-3.5-flash-lite');

  final GenerativeModel _model;
  final Duration timeout;

  @override
  Future<NutritionInfo> analyzeImage(Uint8List bytes, String mimeType) async {
    AiFoodPrompt.checkImage(bytes, mimeType);
    return _run(Content.multi([
      const TextPart(AiFoodPrompt.instruction),
      InlineDataPart(mimeType, bytes),
    ]));
  }

  @override
  Future<NutritionInfo> analyzeText(String description) async =>
      _run(Content.text(AiFoodPrompt.textPrompt(description)));

  Future<NutritionInfo> _run(Content prompt) async {
    String? text;
    try {
      final res = await _model.generateContent([prompt]).timeout(timeout);
      text = res.text;
    } on TimeoutException {
      throw const AiAnalysisException('AI ใช้เวลานานเกินไป กรุณาลองใหม่');
    } catch (e) {
      debugPrint('Gemini error: $e'); // ดูสาเหตุจริงใน Debug Console เช่น App Check ปฏิเสธ
      throw const AiAnalysisException('AI วิเคราะห์ไม่สำเร็จ กรุณาลองใหม่');
    }
    return AiFoodPrompt.parse(text);
  }
}