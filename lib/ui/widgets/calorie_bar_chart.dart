import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/stats_summary.dart';

/// กราฟแท่งแคลอรี่ต่อวัน + เส้นเป้าหมาย (แท่งสุดท้ายคือวันนี้)
class CalorieBarChart extends StatelessWidget {
  const CalorieBarChart({super.key, required this.days, required this.goal});

  final List<DayCalories> days;
  final double goal;

  static const _weekdayShort = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final peak = days.fold<double>(goal, (m, d) => math.max(m, d.calories));
    final maxValue = peak <= 0 ? 1.0 : peak * 1.1;
    final weekly = days.length <= 7;
    final gap = weekly ? 6.0 : 1.5;
    final last = days.length - 1;

    Color colorFor(int i) {
      if (days[i].calories > goal) return scheme.error;
      return i == last
          ? scheme.primary
          : scheme.primary.withValues(alpha: 0.45);
    }

    String labelFor(int i) {
      if (i == last) return 'วันนี้';
      if (weekly) return _weekdayShort[days[i].day.weekday - 1];
      return (last - i) % 5 == 0 ? '${days[i].day.day}' : '';
    }

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: Stack(
            children: [
              Positioned.fill(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < days.length; i++)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: gap / 2),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              widthFactor: 1,
                              heightFactor: (days[i].calories / maxValue)
                                  .clamp(0.0, 1.0)
                                  .toDouble(),
                              child: DecoratedBox(
                                key: Key('statsBar_$i'),
                                decoration: BoxDecoration(
                                  color: colorFor(i),
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(weekly ? 8 : 3),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // เส้นเป้าหมาย (เส้นประ) วาดทับแท่ง
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _GoalLinePainter(
                      fraction: (goal / maxValue).clamp(0.0, 1.0).toDouble(),
                      color: scheme.outline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 20,
          child: Row(
            children: [
              for (var i = 0; i < days.length; i++)
                Expanded(
                  child: Center(
                    child: OverflowBox(
                      minWidth: 0,
                      maxWidth: 56,
                      child: Text(
                        labelFor(i),
                        softWrap: false,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: text.bodySmall?.copyWith(
                          color: i == last
                              ? scheme.onSurface
                              : scheme.onSurfaceVariant,
                          fontWeight: i == last
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GoalLinePainter extends CustomPainter {
  _GoalLinePainter({required this.fraction, required this.color});

  final double fraction;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * (1 - fraction);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    const dash = 6.0;
    const gap = 4.0;
    for (var x = 0.0; x < size.width; x += dash + gap) {
      canvas.drawLine(
        Offset(x, y),
        Offset(math.min(x + dash, size.width), y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_GoalLinePainter old) =>
      old.fraction != fraction || old.color != color;
}
