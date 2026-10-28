import 'package:flutter/foundation.dart';

import '../data/food_repository.dart';
import '../models/daily_summary.dart';
import '../models/food_entry.dart';
import '../models/meal_type.dart';

/// สถานะของหน้าหลัก (ต่อผู้ใช้หนึ่งคน) — หน้าจอเรียกใช้ผ่าน provider
class FoodLogController extends ChangeNotifier {
  FoodLogController({required this.repository, required this.uid, DateTime Function()? clock})
      : _clock = clock ?? DateTime.now {
    _selectedDay = _dayOf(_clock());
  }

  final FoodRepository repository;
  final String uid;
  final DateTime Function() _clock;

  late DateTime _selectedDay;
  List<FoodEntry> _entries = const [];
  double _goal = FoodRepository.defaultGoal;
  bool _loading = false;
  bool _syncing = false;
  int _pending = 0;
  String? _message;
  bool _disposed = false;

  DateTime get selectedDay => _selectedDay;
  List<FoodEntry> get entries => _entries;
  double get goal => _goal;
  bool get loading => _loading;
  bool get syncing => _syncing;
  int get pendingCount => _pending;
  DateTime now() => _clock();
  bool get isToday => _selectedDay == _dayOf(_clock());
  DailySummary get summary => DailySummary.fromEntries(_entries, goal: _goal);

  /// ข้อความแจ้งเตือนครั้งเดียว — หน้าจออ่านแล้วล้างทิ้ง
  String? consumeMessage() {
    final m = _message;
    _message = null;
    return m;
  }

  static DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _reload() async {
    _entries = await repository.entriesForDay(uid, _selectedDay);
    _pending = await repository.pendingCount(uid);
  }

  Future<void> init() async {
    _loading = true;
    _notify();
    _goal = await repository.dailyGoal(uid);
    await _reload();
    _loading = false;
    _notify();
    await sync(silent: true); // ดึงข้อมูลจาก cloud เบื้องหลัง
  }

  Future<void> selectDay(DateTime day) async {
    _selectedDay = _dayOf(day);
    await _reload();
    _notify();
  }

  Future<void> previousDay() => selectDay(
      DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day - 1));

  Future<void> nextDay() async {
    if (isToday) return; // ไปอนาคตไม่ได้
    await selectDay(
        DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day + 1));
  }

  /// เพิ่มอาหารลงวันที่เลือกอยู่
  Future<void> addEntry({
    required String name,
    required double calories,
    double protein = 0,
    double carbs = 0,
    double fat = 0,
    MealType? mealType,
  }) {
    final eatenAt = isToday
        ? _clock()
        : DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day, 12);
    return saveEntry(FoodEntry(
      id: FoodEntry.newId(),
      userId: uid,
      name: name,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      mealType: mealType ?? MealType.suggestFor(eatenAt),
      eatenAt: eatenAt,
    ));
  }

  Future<void> saveEntry(FoodEntry entry) async {
    final ok = await repository.save(uid, entry);
    _message = ok ? 'บันทึก "${entry.name}" แล้ว' : 'บันทึกในเครื่องแล้ว จะซิงก์เมื่อออนไลน์';
    await _reload();
    _notify();
  }

  Future<void> deleteEntry(FoodEntry entry) async {
    await repository.delete(uid, entry.id);
    _message = 'ลบ "${entry.name}" แล้ว';
    await _reload();
    _notify();
  }

  Future<void> setGoal(double goal) async {
    await repository.setDailyGoal(uid, goal);
    _goal = await repository.dailyGoal(uid);
    _notify();
  }

  Future<SyncResult?> sync({bool silent = false}) async {
    if (_syncing) return null;
    _syncing = true;
    _notify();
    final result = await repository.sync(uid);
    await _reload();
    _syncing = false;
    if (!silent) {
      _message = result.hasFailures
          ? 'ซิงก์ไม่สำเร็จ (ค้าง $_pending รายการ)'
          : 'ซิงก์ข้อมูลกับ Cloud เรียบร้อย';
    }
    _notify();
    return result;
  }

  /// แคลอรี่รวมย้อนหลัง [days] วัน (เก่าสุดก่อน) — สำหรับหน้าสถิติ
  Future<List<({DateTime day, double calories})>> history(int days) async {
    final end = _dayOf(_clock());
    final list = [
      for (var i = days - 1; i >= 0; i--) DateTime(end.year, end.month, end.day - i)
    ];
    final entries = await repository.entriesForRange(uid, list.first, list.last);
    return [
      for (final d in list)
        (
          day: d,
          calories: entries
              .where((e) => _dayOf(e.eatenAt) == d)
              .fold<double>(0, (sum, e) => sum + e.calories),
        ),
    ];
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}