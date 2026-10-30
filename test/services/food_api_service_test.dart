import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:food_log/models/nutrition_info.dart';
import 'package:food_log/services/food_api_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// ตอบกลับเป็น JSON (UTF-8 รองรับภาษาไทย)
http.Response jsonResponse(Object body, [int status = 200]) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

void main() {
  final sample = {
    'products': [
      {
        'product_name_th': 'นมจืด UHT',
        'product_name': 'UHT Milk',
        'brands': 'Foremost, Thailand',
        'nutriments': {
          'energy-kcal_100g': 63,
          'proteins_100g': 3.2,
          'carbohydrates_100g': 4.8,
          'fat_100g': '3.5', // บางครั้ง API ส่งเป็นข้อความ
        },
      },
      {
        'product_name': 'Peanut Butter',
        'nutriments': {'energy_100g': 2510}, // มีแค่ kJ
      },
      {'product_name': 'No energy', 'nutriments': {}}, // ไม่มีพลังงาน → ข้าม
      {'product_name': '', 'nutriments': {'energy-kcal_100g': 10}}, // ไม่มีชื่อ → ข้าม
    ],
  };

  test('ค้นหาสำเร็จ: ใช้ชื่อไทยก่อน ข้ามสินค้าที่ข้อมูลไม่ครบ และแปลง kJ เป็น kcal', () async {
    final api = OpenFoodFactsService(MockClient((_) async => jsonResponse(sample)));

    final results = await api.search('นม');

    expect(results, hasLength(2));
    expect(results[0].name, 'นมจืด UHT');
    expect(results[0].brand, 'Foremost');
    expect(results[0].calories, 63);
    expect(results[0].fat, 3.5);
    expect(results[1].name, 'Peanut Butter');
    expect(results[1].calories, closeTo(600, 1)); // 2510 kJ ≈ 600 kcal
  });

  test('ส่ง User-Agent และค่าพารามิเตอร์ที่ถูกต้อง', () async {
    late http.Request sent;
    final api = OpenFoodFactsService(MockClient((req) async {
      sent = req;
      return jsonResponse({'products': []});
    }));

    await api.search('กะเพรา');

    expect(sent.url.host, 'world.openfoodfacts.org');
    expect(sent.url.scheme, 'https');
    expect(sent.url.queryParameters['search_terms'], 'กะเพรา');
    expect(sent.headers['User-Agent'], contains('FoodLog'));
  });

  test('คำค้นสั้นกว่า 2 ตัวอักษร → ไม่เรียกเน็ต', () async {
    var calls = 0;
    final api = OpenFoodFactsService(MockClient((_) async {
      calls++;
      return jsonResponse({'products': []});
    }));

    expect(await api.search(' '), isEmpty);
    expect(await api.search('ก'), isEmpty);
    expect(calls, 0);
  });

  group('error เป็นข้อความไทย', () {
    Future<void> expectError(MockClient client, String message,
        {Duration timeout = const Duration(seconds: 15)}) async {
      final api = OpenFoodFactsService(client, timeout: timeout);
      await expectLater(
        api.search('นม'),
        throwsA(isA<FoodApiException>().having((e) => e.message, 'message', message)),
      );
    }

    test('เซิร์ฟเวอร์ล่ม (500)', () => expectError(
        MockClient((_) async => http.Response('oops', 500)),
        'เซิร์ฟเวอร์ตอบกลับผิดพลาด (500)'));

    test('ค้นบ่อยเกิน (429)', () => expectError(
        MockClient((_) async => http.Response('slow down', 429)),
        'ค้นหาบ่อยเกินไป กรุณารอสักครู่'));

    test('JSON เสีย', () => expectError(
        MockClient((_) async => http.Response('<html>', 200)),
        'ข้อมูลจากเซิร์ฟเวอร์ไม่ถูกต้อง'));

    test('JSON ผิดรูปแบบ (ไม่มี products)', () => expectError(
        MockClient((_) async => jsonResponse({'error': 'x'})),
        'ข้อมูลจากเซิร์ฟเวอร์ไม่ถูกต้อง'));

    test('ไม่มีเน็ต', () => expectError(
        MockClient((_) async => throw http.ClientException('no network')),
        'เชื่อมต่ออินเทอร์เน็ตไม่ได้'));

    test('หมดเวลา', () => expectError(
        MockClient((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 200));
          return jsonResponse({'products': []});
        }),
        'หมดเวลาเชื่อมต่อ กรุณาลองใหม่',
        timeout: const Duration(milliseconds: 20)));
  });

  group('ความปลอดภัย', () {
    test('คำค้นที่พยายามแทรกพารามิเตอร์ถูก encode เป็นข้อความธรรมดา', () async {
      late Uri url;
      final api = OpenFoodFactsService(MockClient((req) async {
        url = req.url;
        return jsonResponse({'products': []});
      }));

      await api.search('milk&page_size=9999&json=0');

      expect(url.queryParameters['search_terms'], 'milk&page_size=9999&json=0');
      expect(url.queryParameters['page_size'], '15');
      expect(url.queryParameters['json'], '1');
    });

    test('คำค้นถูกลบ HTML และตัดความยาวไม่เกิน 60 ตัว', () async {
      late Uri url;
      final api = OpenFoodFactsService(MockClient((req) async {
        url = req.url;
        return jsonResponse({'products': []});
      }));

      await api.search('<script>x</script>${'ก' * 100}');

      final q = url.queryParameters['search_terms']!;
      expect(q, isNot(contains('<script>')));
      expect(q.length, OpenFoodFactsService.maxQueryLength);
    });

    test('ค่าจาก API ที่ผิดปกติถูกจำกัด (ติดลบ/ใหญ่เกิน)', () {
      final info = OpenFoodFactsService.parseProduct({
        'product_name': 'Weird',
        'nutriments': {'energy-kcal_100g': 999999, 'fat_100g': -5},
      })!;
      expect(info.calories, 5000);
      expect(info.fat, 0);
    });
  });

  test('NutritionInfo.scaledTo ปรับตามปริมาณ', () {
    final per100 = NutritionInfo(name: 'ข้าว', calories: 130, carbs: 28);
    final plate = per100.scaledTo(250);
    expect(plate.calories, 325);
    expect(plate.carbs, 70);
    expect(plate.servingGrams, 250);
    expect(per100.scaledTo(0), same(per100));
  });
}