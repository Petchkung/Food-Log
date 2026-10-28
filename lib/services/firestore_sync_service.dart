import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/food_entry.dart';
import 'cloud_sync_service.dart';

/// Cloud Firestore: users/{uid}/entries/{entryId}
class FirestoreSyncService implements CloudSyncService {
  FirestoreSyncService([FirebaseFirestore? db])
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _entries(String uid) {
    CloudSyncService.assertSafeId(uid);
    return _db.collection('users').doc(uid).collection('entries');
  }

  @override
  Future<void> upsert(String uid, FoodEntry entry) async {
    if (entry.userId != uid) {
      throw const CloudSyncException('ไม่มีสิทธิ์บันทึกข้อมูลของผู้ใช้อื่น');
    }
    CloudSyncService.assertSafeId(entry.id);
    try {
      await _entries(uid).doc(entry.id).set(entry.toCloudMap());
    } on FirebaseException catch (e) {
      throw CloudSyncException(e.message ?? e.code);
    }
  }

  @override
  Future<void> delete(String uid, String entryId) async {
    CloudSyncService.assertSafeId(entryId);
    try {
      await _entries(uid).doc(entryId).delete();
    } on FirebaseException catch (e) {
      throw CloudSyncException(e.message ?? e.code);
    }
  }

  @override
  Future<List<FoodEntry>> fetchAll(String uid) async {
    try {
      final snap = await _entries(uid).get();
      return snap.docs
          .map((d) => FoodEntry.fromCloudMap(d.data()))
          .where((e) => e.userId == uid)
          .toList();
    } on FirebaseException catch (e) {
      throw CloudSyncException(e.message ?? e.code);
    }
  }
}