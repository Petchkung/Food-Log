import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/thai_format.dart';
import '../../models/meal_type.dart';
import '../../services/auth_service.dart';
import '../../state/food_log_controller.dart';
import '../widgets/calorie_ring_card.dart';
import '../widgets/home_header.dart';
import '../widgets/meal_card.dart';
import 'add_food_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.user,
    required this.auth,
    this.onOpenStats,
  });

  final AppUser user;
  final AuthService auth;

  /// กด "ดูสถิติ" (MainShell ส่งมาให้ เพื่อสลับไปแท็บสถิติ)
  final VoidCallback? onOpenStats;

  /// เปิดหน้าเพิ่มอาหาร โดยเลือกมื้อที่กดไว้ให้
  /// (ต้องส่ง controller ต่อให้ เพราะหน้าที่ push อยู่เหนือ Provider)
  void _openAdd(BuildContext context, FoodLogController c, MealType meal) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider<FoodLogController>.value(
          value: c,
          child: AddFoodScreen(initialMeal: meal),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<FoodLogController>();
    final s = c.summary;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final msg = c.consumeMessage();
    if (msg != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        }
      });
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: c.loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  HomeHeader(
                    day: c.selectedDay,
                    name: ThaiFormat.nameFromEmail(user.email),
                    syncing: c.syncing,
                    pendingCount: c.pendingCount,
                    onSync: () => c.sync(),
                    onPreviousDay: c.previousDay,
                    onNextDay: c.isToday ? null : c.nextDay,
                  ),
                  const SizedBox(height: 16),
                  CalorieRingCard(summary: s, isToday: c.isToday),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.isToday ? 'มื้ออาหารวันนี้' : 'มื้ออาหาร',
                          style: text.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (onOpenStats != null)
                        TextButton(
                          key: const Key('openStatsButton'),
                          onPressed: onOpenStats,
                          child: const Text('ดูสถิติ'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (final meal in MealType.values)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: MealCard(
                        meal: meal,
                        calories: s.caloriesByMeal[meal] ?? 0,
                        entries: [
                          for (final e in c.entries)
                            if (e.mealType == meal) e,
                        ],
                        onAdd: () => _openAdd(context, c, meal),
                        onDelete: c.deleteEntry,
                      ),
                    ),
                  if (c.entries.isEmpty)
                    Padding(
                      key: const Key('emptyState'),
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'ยังไม่มีรายการ กด + ที่มื้อเพื่อเพิ่มอาหาร',
                        textAlign: TextAlign.center,
                        style: text.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}