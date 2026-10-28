import 'package:food_log/models/food_entry.dart';
import 'package:food_log/services/cloud_sync_service.dart';

/// Firestore ปลอม — เก็บใน Map และจำลอง "เน็ตหลุด" ได้
class FakeCloudSync implements CloudSyncService {
  final Map<String, Map<String, FoodEntry>> store = {};
  bool offline = false;

  void _checkOnline() {
    if (offline) throw const CloudSyncException('offline');
  }

  @override
  Future<void> upsert(String uid, FoodEntry entry) async {
    _checkOnline();
    CloudSyncService.assertSafeId(uid);
    if (entry.userId != uid) throw const CloudSyncException('forbidden');
    store.putIfAbsent(uid, () => {})[entry.id] = entry.copyWith(synced: true);
  }

  @override
  Future<void> delete(String uid, String entryId) async {
    _checkOnline();
    store[uid]?.remove(entryId);
  }

  @override
  Future<List<FoodEntry>> fetchAll(String uid) async {
    _checkOnline();
    return (store[uid]?.values ?? const <FoodEntry>[]).toList();
  }
}