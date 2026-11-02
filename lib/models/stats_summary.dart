/// แคลอรี่รวมของ 1 วัน (ใช้กับกราฟและสรุปในหน้าสถิติ)
typedef DayCalories = ({DateTime day, double calories});

/// ตัวเลขสรุปของช่วงที่เลือก (สัปดาห์/เดือน)
class StatsSummary {
  const StatsSummary({
    required this.averageCalories,
    required this.daysOverGoal,
    required this.loggedDays,
  });

  /// คำนวณจากรายวัน: เฉลี่ยและนับเกินเป้า เฉพาะวันที่มีบันทึก (แคลอรี่ > 0)
  factory StatsSummary.fromDays(List<DayCalories> days, double goal) {
    final logged = days.where((d) => d.calories > 0).toList();
    if (logged.isEmpty) {
      return const StatsSummary(
        averageCalories: 0,
        daysOverGoal: 0,
        loggedDays: 0,
      );
    }
    final total = logged.fold<double>(0, (sum, d) => sum + d.calories);
    return StatsSummary(
      averageCalories: total / logged.length,
      daysOverGoal: logged.where((d) => d.calories > goal).length,
      loggedDays: logged.length,
    );
  }

  final double averageCalories;
  final int daysOverGoal;
  final int loggedDays;
}
