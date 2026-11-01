import 'package:flutter/material.dart';

import '../../core/thai_format.dart';
import '../../models/daily_summary.dart';
import '../../models/macro_targets.dart';

/// แถบโปรตีน / คาร์บ / ไขมัน เทียบกับเป้าหมายของวัน
class MacroBars extends StatelessWidget {
  const MacroBars({super.key, required this.summary});

  final DailySummary summary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final targets = MacroTargets.fromCalories(summary.goal);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _MacroColumn(
            keyPrefix: 'macroProtein',
            label: 'โปรตีน',
            value: summary.protein,
            target: targets.protein,
            color: scheme.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _MacroColumn(
            keyPrefix: 'macroCarbs',
            label: 'คาร์บ',
            value: summary.carbs,
            target: targets.carbs,
            color: scheme.secondary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _MacroColumn(
            keyPrefix: 'macroFat',
            label: 'ไขมัน',
            value: summary.fat,
            target: targets.fat,
            color: scheme.tertiary,
          ),
        ),
      ],
    );
  }
}

class _MacroColumn extends StatelessWidget {
  const _MacroColumn({
    required this.keyPrefix,
    required this.label,
    required this.value,
    required this.target,
    required this.color,
  });

  final String keyPrefix;
  final String label;
  final double value;
  final double target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final progress = target <= 0
        ? 0.0
        : (value / target).clamp(0.0, 1.0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          key: Key('${keyPrefix}Bar'),
          value: progress,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
          color: color,
          backgroundColor: scheme.surfaceContainerHighest,
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: ThaiFormat.number(value),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                TextSpan(text: ' / ${ThaiFormat.number(target)} g'),
              ],
            ),
            key: Key('${keyPrefix}Value'),
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
