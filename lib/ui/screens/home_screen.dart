import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/thai_format.dart';
import '../../models/food_entry.dart';
import '../../models/meal_type.dart';
import '../../services/auth_service.dart';
import '../../state/food_log_controller.dart';
import '../widgets/calorie_ring_card.dart';
import '../widgets/home_header.dart';
import 'add_food_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.user, required this.auth});

  final AppUser user;
  final AuthService auth;

  /// เปิดหน้าเพิ่มอาหาร (ต้องส่ง controller ต่อให้ เพราะหน้าที่ push อยู่เหนือ Provider)
  void _openAdd(BuildContext context, FoodLogController c) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider<FoodLogController>.value(
          value: c,
          child: AddFoodScreen(initialMeal: MealType.suggestFor(c.now())),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<FoodLogController>();

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
                    onSignOut: auth.signOut,
                  ),
                  const SizedBox(height: 16),
                  CalorieRingCard(summary: c.summary, isToday: c.isToday),
                  const SizedBox(height: 8),
                  if (c.entries.isEmpty)
                    const Padding(
                      key: Key('emptyState'),
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'ยังไม่มีรายการวันนี้ กด + เพื่อเพิ่มอาหาร',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  for (final FoodEntry e in c.entries)
                    ListTile(
                      key: ValueKey(e.id),
                      leading: Icon(e.mealType.icon),
                      title: Text(e.name),
                      subtitle: Text(
                        '${e.mealType.label} · ${e.calories.round()} kcal',
                      ),
                      trailing: IconButton(
                        tooltip: 'ลบ',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => c.deleteEntry(e),
                      ),
                    ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('addFoodButton'),
        onPressed: () => _openAdd(context, c),
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มอาหาร'),
      ),
    );
  }
}