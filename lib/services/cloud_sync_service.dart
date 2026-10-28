import '../models/food_entry.dart';

class CloudSyncException implements Exception {
  const CloudSyncException(this.message);
  final String message;
  @override
  String toString() => 'CloudSyncException($message)';
}

/// เก็บข้อมูลบน cloud ที่ users/{uid}/entries/{entryId}
abstract class CloudSyncService {
  Future<void> upsert(String uid, FoodEntry entry);
  Future<void> delete(String uid, String entryId);
  Future<List<FoodEntry>> fetchAll(String uid);

  /// กัน id แปลก ๆ เช่น "abc/../คนอื่น" ที่อาจทำให้เขียนไปผิด path
  static void assertSafeId(String id) {
    if (id.isEmpty || id.length > 128 || !RegExp(r'^[A-Za-z0-9_\-]+$').hasMatch(id)) {
      throw const CloudSyncException('รหัสไม่ถูกต้อง');
    }
  }
}