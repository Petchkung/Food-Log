import 'package:food_log/data/food_repository.dart';
import 'package:food_log/data/local_database.dart';
import 'package:food_log/models/food_entry.dart';
import 'package:food_log/services/cloud_sync_service.dart';

/// Repository ปลอม เก็บใน List — ใช้กับ widget test (ไม่ต้องใช้ SQLite จริง)
class FakeFoodRepository implements FoodRepository {
  final List<FoodEntry> items = [];
  double goal = FoodRepository.defaultGoal;
  int syncCalls = 0;

  @override
  LocalDatabase get local => throw UnimplementedError();
  @override
  CloudSyncService get cloud => throw UnimplementedError();

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Future<List<FoodEntry>> entriesForDay(String uid, DateTime day) async => items
      .where((e) => e.userId == uid && !e.deleted && _day(e.eatenAt) == _day(day))
      .toList()
    ..sort((a, b) => a.eatenAt.compareTo(b.eatenAt));

  @override
  Future<List<FoodEntry>> entriesForRange(String uid, DateTime from, DateTime to) async =>
      items
          .where((e) =>
              e.userId == uid &&
              !e.deleted &&
              !_day(e.eatenAt).isBefore(_day(from)) &&
              !_day(e.eatenAt).isAfter(_day(to)))
          .toList();

  @override
  Future<bool> save(String uid, FoodEntry entry) async {
    items.removeWhere((e) => e.id == entry.id);
    items.add(entry.copyWith(synced: true));
    return true;
  }

  @override
  Future<bool> delete(String uid, String entryId) async {
    final before = items.length;
    items.removeWhere((e) => e.id == entryId && e.userId == uid);
    return items.length < before;
  }

  @override
  Future<SyncResult> sync(String uid) async {
    syncCalls++;
    return const SyncResult();
  }

  @override
  Future<int> pendingCount(String uid) async => 0;

  @override
  Future<double> dailyGoal(String uid) async => goal;

  @override
  Future<void> setDailyGoal(String uid, double g) async =>
      goal = g.clamp(800, 6000).toDouble();
}