/// ตัวช่วยแสดงผลภาษาไทย (ไม่ใช้ intl จะได้ไม่ต้องตั้งค่า locale เพิ่ม)
class ThaiFormat {
  ThaiFormat._();

  static const _weekdays = [
    'จันทร์',
    'อังคาร',
    'พุธ',
    'พฤหัสบดี',
    'ศุกร์',
    'เสาร์',
    'อาทิตย์',
  ];

  static const _months = [
    'ม.ค.',
    'ก.พ.',
    'มี.ค.',
    'เม.ย.',
    'พ.ค.',
    'มิ.ย.',
    'ก.ค.',
    'ส.ค.',
    'ก.ย.',
    'ต.ค.',
    'พ.ย.',
    'ธ.ค.',
  ];

  /// เช่น "พุธ 28 ต.ค."
  static String date(DateTime d) =>
      '${_weekdays[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';

  /// ชื่อที่ใช้ทักทาย: ใช้ส่วนหน้า @ ของอีเมล (แอปยังไม่มีช่องกรอกชื่อ)
  static String nameFromEmail(String email) {
    final local = email.split('@').first.trim();
    return local.isEmpty ? 'ผู้ใช้' : local;
  }

  /// ตัวอักษรแรกสำหรับอวาตาร์
  static String initial(String name) {
    final t = name.trim();
    if (t.isEmpty) return '?';
    return String.fromCharCode(t.runes.first).toUpperCase();
  }

  /// ปัดเป็นจำนวนเต็มและใส่คอมมาหลักพัน เช่น 1240 → "1,240"
  static String number(num value) {
    final rounded = value.round();
    final digits = rounded.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return rounded < 0 ? '-$buffer' : buffer.toString();
  }
}
