import 'dart:typed_data';

import 'package:food_log/services/photo_picker.dart';

/// กล้อง/แกลเลอรีปลอม — คืนรูปที่กำหนด, คืน null (ผู้ใช้ยกเลิก) หรือจำลอง error
class FakePhotoPicker implements PhotoPicker {
  FakePhotoPicker({PickedPhoto? photo})
      : photo = photo ??
            PickedPhoto(
              bytes: Uint8List.fromList([0xFF, 0xD8, 0xFF]),
              mimeType: 'image/jpeg',
            );

  /// null = จำลองว่าผู้ใช้กดยกเลิก
  PickedPhoto? photo;
  Exception? error;
  final List<PhotoSource> calls = [];

  @override
  Future<PickedPhoto?> pick(PhotoSource source) async {
    calls.add(source);
    if (error != null) throw error!;
    return photo;
  }
}
