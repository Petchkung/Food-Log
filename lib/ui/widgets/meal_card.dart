import 'package:flutter/material.dart';

import '../../core/thai_format.dart';
import '../../models/food_entry.dart';
import '../../models/meal_type.dart';

/// การ์ดของมื้ออาหาร 1 มื้อ: ไอคอน, ชื่อมื้อ + แคลอรี่รวม, ปุ่ม + และรายการอาหารในมื้อนั้น
class MealCard extends StatelessWidget {
  const MealCard({
    super.key,
    required this.meal,
    required this.calories,
    required this.entries,
    required this.onAdd,
    required this.onDelete,
  });

  final MealType meal;
  final double calories;
  final List<FoodEntry> entries;
  final VoidCallback onAdd;
  final ValueChanged<FoodEntry> onDelete;

  Color _iconBackground(ColorScheme scheme) => switch (meal) {
    MealType.breakfast => scheme.tertiaryContainer,
    MealType.lunch => scheme.primaryContainer,
    MealType.dinner => scheme.secondaryContainer,
    MealType.snack => scheme.surfaceContainerHighest,
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final hasItems = entries.isNotEmpty;

    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _iconBackground(scheme),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(meal.icon, color: scheme.onSurface),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: meal.label),
                          if (hasItems)
                            TextSpan(
                              text: ' · ${ThaiFormat.number(calories)} kcal',
                              style: TextStyle(color: scheme.primary),
                            ),
                        ],
                      ),
                      key: Key('mealTitle_${meal.name}'),
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (!hasItems)
                      Text(
                        'ยังไม่มีรายการ',
                        style: text.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                key: Key('addMeal_${meal.name}'),
                tooltip: 'เพิ่ม${meal.label}',
                icon: const Icon(Icons.add),
                onPressed: onAdd,
              ),
            ],
          ),
          for (final e in entries)
            ListTile(
              key: ValueKey(e.id),
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(e.name),
              subtitle: Text('${ThaiFormat.number(e.calories)} kcal'),
              trailing: IconButton(
                tooltip: 'ลบ',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => onDelete(e),
              ),
            ),
        ],
      ),
    );

    // มื้อที่มีรายการ = การ์ดปกติ, มื้อที่ยังว่าง = การ์ดแบบมีกรอบ
    return hasItems
        ? Card(margin: EdgeInsets.zero, child: content)
        : Card.outlined(margin: EdgeInsets.zero, child: content);
  }
}
