import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/food_entry.dart';
import 'cloud_sync_service.dart';

/// Cloud Firestore: users/{uid}/entries/{entryId}
class FirestoreSyncService implements CloudSyncService {
  FirestoreSyncService([FirebaseFirestore? db, this.timeout = const Duration(seconds: 4)])
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// ตอนออฟไลน์ Firestore จะรอเน็ตไปเรื่อย ๆ (ไม่ error) — เกินเวลานี้ให้ถือว่าออฟไลน์
  /// แล้วให้ Repository เก็บไว้ใน SQLite รอซิงก์ทีหลัง
  final Duration timeout;

  CollectionReference<Map<String, dynamic>> _entries(String uid) {
    CloudSyncService.assertSafeId(uid);
    return _db.collection('users').doc(uid).collection('entries');
  }

  Future<T> _run<T>(Future<T> Function() action) async {
    try {
      return await action().timeout(timeout);
    } on TimeoutException {
      throw const CloudSyncException('ออฟไลน์ — จะซิงก์เมื่อเชื่อมต่ออินเทอร์เน็ต');
    } on FirebaseException catch (e) {
      throw CloudSyncException(e.message ?? e.code);
    }
  }

  @override
  Future<void> upsert(String uid, FoodEntry entry) {
    if (entry.userId != uid) {
      throw const CloudSyncException('ไม่มีสิทธิ์บันทึกข้อมูลของผู้ใช้อื่น');
    }
    CloudSyncService.assertSafeId(entry.id);
    return _run(() => _entries(uid).doc(entry.id).set(entry.toCloudMap()));
  }

  @override
  Future<void> delete(String uid, String entryId) {
    CloudSyncService.assertSafeId(entryId);
    return _run(() => _entries(uid).doc(entryId).delete());
  }

  @override
  Future<List<FoodEntry>> fetchAll(String uid) {
    return _run(() async {
      // ขอจาก server เท่านั้น ออฟไลน์จะ error ทันที แทนที่จะได้ข้อมูลเก่าจาก cache
      final snap = await _entries(uid).get(const GetOptions(source: Source.server));
      return snap.docs
          .map((d) => FoodEntry.fromCloudMap(d.data()))
          .where((e) => e.userId == uid)
          .toList();
    });
  }
}