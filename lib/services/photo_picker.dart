import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import 'ai_food_analyzer.dart';

enum PhotoSource { camera, gallery }

/// รูปที่ผู้ใช้เลือก พร้อมชนิดไฟล์ (ส่งต่อให้ AI วิเคราะห์)
class PickedPhoto {
  const PickedPhoto({required this.bytes, required this.mimeType});

  final Uint8List bytes;
  final String mimeType;
}

/// หาชนิดไฟล์รูป: เชื่อค่าที่ระบบรายงานถ้าอยู่ในรายการที่รองรับ ไม่งั้นเดาจากนามสกุล
String mimeTypeFromPath(String path, {String? reported}) {
  final r = reported?.toLowerCase();
  if (r != null && AiFoodPrompt.allowedMimeTypes.contains(r)) return r;
  final dot = path.lastIndexOf('.');
  final ext = dot < 0 ? '' : path.substring(dot + 1).toLowerCase();
  return switch (ext) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    'heic' || 'heif' => 'image/heic',
    _ => 'image/jpeg',
  };
}

/// เลือก/ถ่ายรูป — หน้าจอใช้ผ่าน interface นี้ (เทสต์ใช้ของปลอมได้ ไม่ต้องเปิดกล้องจริง)
abstract class PhotoPicker {
  /// คืน null ถ้าผู้ใช้ยกเลิก
  Future<PickedPhoto?> pick(PhotoSource source);
}

class ImagePickerPhotoPicker implements PhotoPicker {
  const ImagePickerPhotoPicker();

  @override
  Future<PickedPhoto?> pick(PhotoSource source) async {
    final file = await ImagePicker().pickImage(
      source: source == PhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: 1280, // ลดขนาดรูปก่อนส่ง AI (ประหยัดเน็ต และไม่เกิน 4 MB)
      imageQuality: 80,
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    return PickedPhoto(
      bytes: bytes,
      mimeType: mimeTypeFromPath(file.path, reported: file.mimeType),
    );
  }
}