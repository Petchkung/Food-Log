import 'package:flutter_test/flutter_test.dart';
import 'package:food_log/core/validators.dart';

void main() {
  group('Validators.email', () {
    test('ว่างต้องไม่ผ่าน', () {
      expect(Validators.email(''), 'กรุณากรอกอีเมล');
      expect(Validators.email(null), 'กรุณากรอกอีเมล');
    });

    test('รูปแบบผิดต้องไม่ผ่าน', () {
      expect(Validators.email('abc'), isNotNull);
      expect(Validators.email('abc@'), isNotNull);
      expect(Validators.email('a@b'), isNotNull);
    });

    test('อีเมลถูกต้องผ่าน (ตัดช่องว่างหัวท้ายให้)', () {
      expect(Validators.email('student@kmitl.ac.th'), isNull);
      expect(Validators.email('  student@kmitl.ac.th  '), isNull);
    });
  });

  group('Validators.password', () {
    test('ว่างหรือสั้นเกินไม่ผ่าน', () {
      expect(Validators.password(''), 'กรุณากรอกรหัสผ่าน');
      expect(Validators.password('abc123'), contains('อย่างน้อย 8'));
    });

    test('ต้องมีทั้งตัวอักษรและตัวเลข', () {
      expect(Validators.password('abcdefgh'), isNotNull);
      expect(Validators.password('12345678'), isNotNull);
    });

    test('รหัสผ่านที่ดีผ่าน', () {
      expect(Validators.password('foodlog2026'), isNull);
    });
  });
}