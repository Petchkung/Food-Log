import '../models/food_entry.dart';
import '../services/cloud_sync_service.dart';
import 'local_database.dart';

/// ผลการ sync
class SyncResult {
  const SyncResult({this.uploaded = 0, this.deleted = 0, this.downloaded = 0, this.failed = 0});
  final int uploaded;
  final int deleted;
  final int downloaded;
  final int failed;
  bool get hasFailures => failed > 0;
}

/// Offline-first: บันทึกลง SQLite ก่อนเสมอ แล้วค่อยส่งขึ้น Firestore
class FoodRepository {
  FoodRepository({required this.local, required this.cloud});

  final LocalDatabase local;
  final CloudSyncService cloud;

  static const double defaultGoal = 2000;

  void _checkOwner(String uid, FoodEntry e) {
    if (e.userId != uid) {
      throw const CloudSyncException('ไม่มีสิทธิ์จัดการข้อมูลของผู้ใช้อื่น');
    }
  }

  Future<List<FoodEntry>> entriesForDay(String uid, DateTime day) =>
      local.entriesForDay(uid, day);

  Future<List<FoodEntry>> entriesForRange(String uid, DateTime from, DateTime to) =>
      local.entriesBetween(uid, DateTime(from.year, from.month, from.day),
          DateTime(to.year, to.month, to.day + 1));

  /// บันทึก (เพิ่ม/แก้ไข) — คืน true ถ้าส่งขึ้น cloud สำเร็จ
  Future<bool> save(String uid, FoodEntry entry) async {
    _checkOwner(uid, entry);
    final pending = entry.copyWith(synced: false, updatedAt: DateTime.now());
    await local.upsert(pending);
    try {
      await cloud.upsert(uid, pending);
      await local.upsert(pending.copyWith(synced: true));
      return true;
    } catch (_) {
      return false; // ยังอยู่ในเครื่อง รอ sync ทีหลัง
    }
  }

  /// ลบ — คืน true ถ้าลบบน cloud สำเร็จ
  Future<bool> delete(String uid, String entryId) async {
    final existing = await local.getEntry(uid, entryId);
    if (existing == null) return false;
    await local.upsert(
        existing.copyWith(deleted: true, synced: false, updatedAt: DateTime.now()));
    try {
      await cloud.delete(uid, entryId);
      await local.hardDelete(uid, entryId);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// ส่งรายการที่ค้างขึ้น cloud แล้วดึงข้อมูลจาก cloud ลงมารวม
  Future<SyncResult> sync(String uid) async {
    var uploaded = 0, deleted = 0, downloaded = 0, failed = 0;

    for (final e in await local.pendingSync(uid)) {
      try {
        if (e.deleted) {
          await cloud.delete(uid, e.id);
          await local.hardDelete(uid, e.id);
          deleted++;
        } else {
          await cloud.upsert(uid, e);
          await local.upsert(e.copyWith(synced: true));
          uploaded++;
        }
      } catch (_) {
        failed++;
      }
    }

    try {
      for (final remote in await cloud.fetchAll(uid)) {
        if (remote.userId != uid) continue; // ไม่รับข้อมูลของคนอื่น
        final mine = await local.getEntry(uid, remote.id);
        // ไม่ทับรายการที่ยังรอส่งในเครื่อง และเก็บฉบับที่ใหม่กว่า
        if (mine == null || (mine.synced && remote.updatedAt.isAfter(mine.updatedAt))) {
          await local.upsert(remote.copyWith(synced: true));
          downloaded++;
        }
      }
    } catch (_) {
      failed++;
    }

    return SyncResult(
        uploaded: uploaded, deleted: deleted, downloaded: downloaded, failed: failed);
  }

  Future<int> pendingCount(String uid) async => (await local.pendingSync(uid)).length;

  Future<double> dailyGoal(String uid) async =>
      await local.getDailyGoal(uid) ?? defaultGoal;

  Future<void> setDailyGoal(String uid, double goal) =>
      local.setDailyGoal(uid, goal.clamp(800, 6000).toDouble());
}