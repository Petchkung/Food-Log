import 'package:flutter_test/flutter_test.dart';
import 'package:food_log/core/thai_format.dart';

void main() {
  group('ThaiFormat.date', () {
    test('พุธ 28 ต.ค.', () {
      expect(ThaiFormat.date(DateTime(2026, 10, 28)), 'พุธ 28 ต.ค.');
    });

    test('วันจันทร์และวันอาทิตย์', () {
      expect(ThaiFormat.date(DateTime(2026, 1, 5)), 'จันทร์ 5 ม.ค.');
      expect(ThaiFormat.date(DateTime(2026, 11, 1)), 'อาทิตย์ 1 พ.ย.');
    });
  });

  group('ThaiFormat.nameFromEmail', () {
    test('ใช้ส่วนหน้า @', () {
      expect(ThaiFormat.nameFromEmail('min@test.com'), 'min');
      expect(ThaiFormat.nameFromEmail('a.b@c.com'), 'a.b');
    });

    test('ไม่มีชื่อ → ผู้ใช้', () {
      expect(ThaiFormat.nameFromEmail('@test.com'), 'ผู้ใช้');
    });
  });

  group('ThaiFormat.initial', () {
    test('อังกฤษเป็นตัวพิมพ์ใหญ่ ไทยใช้ตัวแรก', () {
      expect(ThaiFormat.initial('min'), 'M');
      expect(ThaiFormat.initial('ปอน'), 'ป');
    });

    test('ว่าง → ?', () {
      expect(ThaiFormat.initial('  '), '?');
    });
  });
}
