/// ตรวจข้อมูลที่ผู้ใช้กรอก — ใช้ในฟอร์ม (คืนข้อความ error หรือ null ถ้าผ่าน)
class Validators {
  Validators._();

  static const int minPasswordLength = 8;

  static final RegExp _email =
      RegExp(r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'กรุณากรอกอีเมล';
    if (v.length > 254 || !_email.hasMatch(v)) return 'รูปแบบอีเมลไม่ถูกต้อง';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'กรุณากรอกรหัสผ่าน';
    if (v.length < minPasswordLength) {
      return 'รหัสผ่านต้องมีอย่างน้อย $minPasswordLength ตัวอักษร';
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(v) || !RegExp(r'\d').hasMatch(v)) {
      return 'รหัสผ่านต้องมีทั้งตัวอักษรและตัวเลข';
    }
    return null;
  }
}