import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/food_entry.dart';

/// ฐานข้อมูล SQLite ในเครื่อง
/// ใช้ "?" + whereArgs ทุกคำสั่ง (parameterized query) เพื่อกัน SQL injection
class LocalDatabase {
  LocalDatabase._(this._db);

  final Database _db;

  static const _entries = 'food_entries';
  static const _settings = 'settings';

  /// เปิดฐานข้อมูล — ตอนเทสต์ส่ง factory = databaseFactoryFfi และ path = inMemoryDatabasePath
  static Future<LocalDatabase> open({DatabaseFactory? factory, String? path}) async {
    final f = factory ?? databaseFactory;
    final dbPath = path ?? p.join(await f.getDatabasesPath(), 'food_log.db');
    final db = await f.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(version: 1, onCreate: _create),
    );
    return LocalDatabase._(db);
  }

  static Future<void> _create(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_entries (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        calories REAL NOT NULL,
        protein REAL NOT NULL DEFAULT 0,
        carbs REAL NOT NULL DEFAULT 0,
        fat REAL NOT NULL DEFAULT 0,
        meal_type TEXT NOT NULL,
        eaten_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0,
        deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_entries_user_time ON $_entries (user_id, eaten_at)');
    await db.execute('''
      CREATE TABLE $_settings (
        user_id TEXT NOT NULL,
        key TEXT NOT NULL,
        value TEXT,
        PRIMARY KEY (user_id, key)
      )
    ''');
  }

  /// เพิ่มใหม่ หรือแทนที่ถ้ามี id นี้อยู่แล้ว
  Future<void> upsert(FoodEntry entry) async {
    await _db.insert(_entries, entry.toDbMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// รายการของผู้ใช้ในช่วงเวลา [from, to) ที่ยังไม่ถูกลบ เรียงตามเวลา
  Future<List<FoodEntry>> entriesBetween(
      String userId, DateTime from, DateTime to) async {
    final rows = await _db.query(
      _entries,
      where: 'user_id = ? AND deleted = 0 AND eaten_at >= ? AND eaten_at < ?',
      whereArgs: [userId, from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
      orderBy: 'eaten_at ASC',
    );
    return rows.map(FoodEntry.fromDbMap).toList();
  }

  /// รายการของวันนั้นทั้งวัน
  Future<List<FoodEntry>> entriesForDay(String userId, DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = DateTime(day.year, day.month, day.day + 1);
    return entriesBetween(userId, start, end);
  }

  Future<FoodEntry?> getEntry(String userId, String id) async {
    final rows = await _db.query(_entries,
        where: 'user_id = ? AND id = ?', whereArgs: [userId, id], limit: 1);
    return rows.isEmpty ? null : FoodEntry.fromDbMap(rows.first);
  }

  /// รายการที่ยังไม่ได้ส่งขึ้น cloud (รวมรายการที่รอลบ)
  Future<List<FoodEntry>> pendingSync(String userId) async {
    final rows = await _db.query(_entries,
        where: 'user_id = ? AND synced = 0',
        whereArgs: [userId],
        orderBy: 'updated_at ASC');
    return rows.map(FoodEntry.fromDbMap).toList();
  }

  /// ลบออกจากเครื่องจริง (ใช้หลังส่งการลบขึ้น cloud แล้ว)
  Future<void> hardDelete(String userId, String id) async {
    await _db.delete(_entries,
        where: 'user_id = ? AND id = ?', whereArgs: [userId, id]);
  }

  Future<double?> getDailyGoal(String userId) async {
    final rows = await _db.query(_settings,
        columns: ['value'],
        where: 'user_id = ? AND key = ?',
        whereArgs: [userId, 'daily_goal'],
        limit: 1);
    if (rows.isEmpty) return null;
    return double.tryParse(rows.first['value'] as String? ?? '');
  }

  Future<void> setDailyGoal(String userId, double goal) async {
    await _db.insert(
      _settings,
      {'user_id': userId, 'key': 'daily_goal', 'value': goal.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> close() => _db.close();
}