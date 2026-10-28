import 'package:flutter_test/flutter_test.dart';
import 'package:food_log/services/auth_service.dart';

void main() {
  test('รหัสผ่านผิดและไม่พบผู้ใช้ ได้ข้อความเดียวกัน (กันเดาอีเมล)', () {
    final a = AuthException.fromCode('wrong-password');
    final b = AuthException.fromCode('user-not-found');
    final c = AuthException.fromCode('invalid-credential');
    expect(a.message, b.message);
    expect(b.message, c.message);
  });

  test('แปลงรหัสที่รู้จักเป็นข้อความไทย', () {
    expect(AuthException.fromCode('invalid-email').message, 'รูปแบบอีเมลไม่ถูกต้อง');
    expect(AuthException.fromCode('network-request-failed').message,
        'เชื่อมต่ออินเทอร์เน็ตไม่ได้');
  });

  test('รหัสที่ไม่รู้จักได้ข้อความกลาง และเก็บรหัสเดิมไว้', () {
    final e = AuthException.fromCode('something-new');
    expect(e.message, 'เกิดข้อผิดพลาด กรุณาลองใหม่');
    expect(e.code, 'something-new');
    expect(e.toString(), 'AuthException(something-new)');
  });
}