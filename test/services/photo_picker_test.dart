import 'package:flutter_test/flutter_test.dart';
import 'package:food_log/services/photo_picker.dart';

void main() {
  group('mimeTypeFromPath', () {
    test('เดาจากนามสกุลไฟล์', () {
      expect(mimeTypeFromPath('/tmp/food.png'), 'image/png');
      expect(mimeTypeFromPath('/tmp/food.WEBP'), 'image/webp');
      expect(mimeTypeFromPath('/tmp/food.heic'), 'image/heic');
      expect(mimeTypeFromPath('/tmp/food.HEIF'), 'image/heic');
      expect(mimeTypeFromPath('/tmp/food.jpg'), 'image/jpeg');
    });

    test('ไม่มีนามสกุล หรือนามสกุลแปลก → jpeg', () {
      expect(mimeTypeFromPath('/tmp/food'), 'image/jpeg');
      expect(mimeTypeFromPath('/tmp/food.bmp'), 'image/jpeg');
    });

    test('เชื่อค่าที่ระบบรายงาน ถ้าอยู่ในรายการที่ AI รองรับ', () {
      expect(mimeTypeFromPath('/tmp/food', reported: 'image/webp'), 'image/webp');
      expect(mimeTypeFromPath('/tmp/food', reported: 'IMAGE/PNG'), 'image/png');
    });

    test('ค่าที่รายงานไม่รองรับ (เช่น gif) → ไม่เชื่อ แล้วเดาจากนามสกุลแทน', () {
      expect(mimeTypeFromPath('/tmp/food.png', reported: 'image/gif'), 'image/png');
    });
  });
}
