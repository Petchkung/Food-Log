import 'package:food_log/models/nutrition_info.dart';
import 'package:food_log/services/food_api_service.dart';

/// API ปลอม — คืนผลที่กำหนดไว้ หรือจำลอง error
class FakeFoodApiService implements FoodApiService {
  FakeFoodApiService({List<NutritionInfo>? results}) : results = results ?? [];

  List<NutritionInfo> results;
  FoodApiException? error;
  final List<String> queries = [];

  @override
  Future<List<NutritionInfo>> search(String query) async {
    queries.add(query);
    if (error != null) throw error!;
    return results.where((r) => r.name.contains(query.trim())).toList();
  }
}