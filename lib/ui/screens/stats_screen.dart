import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/thai_format.dart';
import '../../models/stats_summary.dart';
import '../../state/food_log_controller.dart';
import '../widgets/calorie_bar_chart.dart';

/// แท็บสถิติ: กราฟแคลอรี่ต่อวัน (สัปดาห์/เดือน) + การ์ดสรุป
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _days = 7;
  List<DayCalories>? _data;
  Object? _loadedKey;
  int _requestId = 0;

  /// โหลดประวัติใหม่เมื่อข้อมูลที่เกี่ยวข้องเปลี่ยน (เพิ่ม/ลบอาหาร, ซิงก์, เปลี่ยนเป้า, เปลี่ยนช่วง)
  void _loadIfNeeded(FoodLogController c) {
    final key = (
      _days,
      c.goal,
      c.summary.calories,
      c.entries.length,
      c.pendingCount,
      c.syncing,
      c.selectedDay,
    );
    if (key == _loadedKey) return;
    _loadedKey = key;
    final id = ++_requestId;
    c
        .history(_days)
        .then((list) {
          if (!mounted || id != _requestId) return;
          setState(() => _data = list);
        })
        .catchError((Object _) {
          if (!mounted || id != _requestId) return;
          setState(() => _data = const []);
        });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<FoodLogController>();
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    _loadIfNeeded(c);

    final data = _data;
    final summary = data == null ? null : StatsSummary.fromDays(data, c.goal);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          Text(
            'สถิติ',
            style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          SegmentedButton<int>(
            key: const Key('statsRange'),
            expandedInsets: EdgeInsets.zero,
            segments: const [
              ButtonSegment(value: 7, label: Text('สัปดาห์')),
              ButtonSegment(value: 30, label: Text('เดือน')),
            ],
            selected: {_days},
            onSelectionChanged: (s) => setState(() {
              _days = s.first;
              _data = null;
            }),
          ),
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'แคลอรี่ต่อวัน',
                          style: text.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        'เป้าหมาย ${ThaiFormat.number(c.goal)} kcal',
                        key: const Key('statsGoalLabel'),
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (data == null)
                    const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    CalorieBarChart(days: data, goal: c.goal),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _LegendDot(
                        color: scheme.primary.withValues(alpha: 0.45),
                        label: 'ไม่เกินเป้า',
                      ),
                      const SizedBox(width: 16),
                      _LegendDot(color: scheme.error, label: 'เกินเป้า'),
                    ],
                  ),
                  if (summary != null && summary.loggedDays == 0) ...[
                    const SizedBox(height: 12),
                    Text(
                      'ยังไม่มีข้อมูลในช่วงนี้ ลองบันทึกมื้ออาหารที่หน้าหลัก',
                      key: const Key('statsEmpty'),
                      style: text.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryTile(
                  valueKey: 'statsAverage',
                  value: summary == null
                      ? '–'
                      : ThaiFormat.number(summary.averageCalories),
                  label: 'เฉลี่ย kcal/วัน',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryTile(
                  valueKey: 'statsOverDays',
                  value: summary == null ? '–' : '${summary.daysOverGoal}',
                  label: 'วันที่เกินเป้า',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryTile(
                  valueKey: 'statsLoggedDays',
                  value: summary == null ? '–' : '${summary.loggedDays}',
                  label: 'วันที่บันทึก',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.valueKey,
    required this.value,
    required this.label,
  });

  final String valueKey;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                key: Key(valueKey),
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
