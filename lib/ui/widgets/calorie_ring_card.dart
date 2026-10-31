import 'package:flutter/material.dart';

import '../../core/thai_format.dart';
import '../../models/daily_summary.dart';
import 'macro_bars.dart';

/// การ์ดสรุปแคลอรี่ของวัน: วงแหวนความคืบหน้า + "เหลืออีก ... kcal" + แถบสารอาหาร
class CalorieRingCard extends StatelessWidget {
  const CalorieRingCard({
    super.key,
    required this.summary,
    required this.isToday,
  });

  final DailySummary summary;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final over = summary.isOverGoal;
    final accent = over ? scheme.error : scheme.primary;
    final amount = over ? -summary.remaining : summary.remaining;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        key: const Key('calorieRing'),
                        value: summary.progress,
                        strokeWidth: 14,
                        strokeCap: StrokeCap.round,
                        backgroundColor: scheme.surfaceContainerHighest,
                        color: accent,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(26),
                        child: FittedBox(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                ThaiFormat.number(summary.calories),
                                key: const Key('calorieTotal'),
                                style: text.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'จาก ${ThaiFormat.number(summary.goal)} kcal',
                                key: const Key('calorieGoal'),
                                style: text.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        over ? 'เกินเป้า' : 'เหลืออีก',
                        style: text.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          ThaiFormat.number(amount),
                          key: const Key('calorieRemaining'),
                          style: text.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                      ),
                      Text(
                        isToday && !over ? 'kcal สำหรับวันนี้' : 'kcal',
                        style: text.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            MacroBars(summary: summary),
          ],
        ),
      ),
    );
  }
}
