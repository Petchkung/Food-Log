import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/food_entry.dart';
import '../models/nutrition_info.dart';

class FoodApiException implements Exception {
  const FoodApiException(this.message);
  final String message;
  @override
  String toString() => 'FoodApiException($message)';
}

/// ค้นหาข้อมูลโภชนาการ — หน้าจอใช้ผ่าน interface นี้ (เทสต์ใช้ของปลอมได้)
abstract class FoodApiService {
  Future<List<NutritionInfo>> search(String query);
}

/// REST API ของ Open Food Facts (ฟรี ไม่ต้องใช้ API key)
class OpenFoodFactsService implements FoodApiService {
  OpenFoodFactsService(this._client, {this.timeout = const Duration(seconds: 15)});

  final http.Client _client;
  final Duration timeout;

  static const int maxQueryLength = 60;
  static const _headers = {
    'User-Agent': 'FoodLog/1.0 (KMITL student project)', // Open Food Facts ขอให้ระบุ
    'Accept': 'application/json',
  };

  /// สร้าง URL ด้วย queryParameters เท่านั้น — คำค้นถูก encode เสมอ (กันการแทรกพารามิเตอร์)
  Uri buildSearchUri(String query) => Uri.https('world.openfoodfacts.org', '/cgi/search.pl', {
        'search_terms': query,
        'search_simple': '1',
        'action': 'process',
        'json': '1',
        'page_size': '15',
        'fields': 'product_name,product_name_th,brands,nutriments',
      });

  @override
  Future<List<NutritionInfo>> search(String query) async {
    var q = FoodEntry.cleanName(query);
    if (q.length > maxQueryLength) q = q.substring(0, maxQueryLength);
    if (q.length < 2) return const []; // สั้นไป ไม่ต้องเรียกเน็ต

    final http.Response res;
    try {
      res = await _client.get(buildSearchUri(q), headers: _headers).timeout(timeout);
    } on TimeoutException {
      throw const FoodApiException('หมดเวลาเชื่อมต่อ กรุณาลองใหม่');
    } on SocketException {
      throw const FoodApiException('เชื่อมต่ออินเทอร์เน็ตไม่ได้');
    } on http.ClientException {
      throw const FoodApiException('เชื่อมต่ออินเทอร์เน็ตไม่ได้');
    }

    if (res.statusCode == 429) {
      throw const FoodApiException('ค้นหาบ่อยเกินไป กรุณารอสักครู่');
    }
    if (res.statusCode != 200) {
      throw FoodApiException('เซิร์ฟเวอร์ตอบกลับผิดพลาด (${res.statusCode})');
    }

    final Object? json;
    try {
      json = jsonDecode(utf8.decode(res.bodyBytes));
    } on FormatException {
      throw const FoodApiException('ข้อมูลจากเซิร์ฟเวอร์ไม่ถูกต้อง');
    }
    if (json is! Map || json['products'] is! List) {
      throw const FoodApiException('ข้อมูลจากเซิร์ฟเวอร์ไม่ถูกต้อง');
    }

    return (json['products'] as List)
        .whereType<Map>()
        .map(parseProduct)
        .whereType<NutritionInfo>()
        .toList();
  }

  /// แปลงสินค้า 1 ชิ้นเป็น NutritionInfo (ค่าต่อ 100 g) — คืน null ถ้าไม่มีชื่อหรือไม่มีพลังงาน
  static NutritionInfo? parseProduct(Map p) {
    final th = (p['product_name_th'] as Object?)?.toString().trim() ?? '';
    final en = (p['product_name'] as Object?)?.toString().trim() ?? '';
    final name = th.isNotEmpty ? th : en;
    if (name.isEmpty) return null;

    final n = p['nutriments'];
    if (n is! Map) return null;

    var kcal = _num(n['energy-kcal_100g']);
    if (kcal == null) {
      final kj = _num(n['energy_100g']); // บางสินค้ามีแค่กิโลจูล
      if (kj != null) kcal = kj / 4.184;
    }
    if (kcal == null) return null;

    final brand = (p['brands'] as Object?)?.toString().split(',').first.trim();
    return NutritionInfo(
      name: name,
      brand: (brand == null || brand.isEmpty) ? null : brand,
      calories: kcal,
      protein: _num(n['proteins_100g']) ?? 0,
      carbs: _num(n['carbohydrates_100g']) ?? 0,
      fat: _num(n['fat_100g']) ?? 0,
    );
  }

  static double? _num(Object? v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}