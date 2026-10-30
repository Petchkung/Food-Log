import 'dart:typed_data';

import 'package:food_log/models/nutrition_info.dart';
import 'package:food_log/services/ai_food_analyzer.dart';

/// AI ปลอม — คืนผลที่กำหนด หรือจำลอง error ได้
class FakeAiFoodAnalyzer implements AiFoodAnalyzer {
  FakeAiFoodAnalyzer({NutritionInfo? result})
      : result = result ??
            NutritionInfo(
              name: 'ข้าวมันไก่',
              calories: 520,
              protein: 28,
              carbs: 62,
              fat: 18,
              servingGrams: 300,
              confidence: 0.86,
            );

  NutritionInfo result;
  AiAnalysisException? error;
  int imageCalls = 0;
  final List<String> texts = [];

  @override
  Future<NutritionInfo> analyzeImage(Uint8List bytes, String mimeType) async {
    imageCalls++;
    if (error != null) throw error!;
    return result;
  }

  @override
  Future<NutritionInfo> analyzeText(String description) async {
    texts.add(description);
    if (error != null) throw error!;
    return result;
  }
}