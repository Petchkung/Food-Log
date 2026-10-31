import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/thai_format.dart';
import '../../models/food_entry.dart';
import '../../models/meal_type.dart';
import '../../services/auth_service.dart';
import '../../state/food_log_controller.dart';
import '../widgets/calorie_ring_card.dart';
import '../widgets/home_header.dart';
import '../widgets/meal_card.dart';

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

  Future<void> _openAdd(
    BuildContext context,
    FoodLogController c,
    MealType meal,
  ) async {
    final result =
        await showDialog<({String name, double calories, MealType meal})>(
          context: context,
          builder: (_) => AddFoodDialog(initialMeal: meal),
        );
    if (result == null) return;
    await c.addEntry(
      name: result.name,
      calories: result.calories,
      mealType: result.meal,
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
                    onSignOut: auth.signOut,
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

/// กล่องเพิ่มอาหารแบบกรอกเอง (ชั่วคราว — หน้าเพิ่มอาหารเต็มรูปแบบจะมาแทน)
class AddFoodDialog extends StatefulWidget {
  const AddFoodDialog({super.key, required this.initialMeal});

  final MealType initialMeal;

  @override
  State<AddFoodDialog> createState() => _AddFoodDialogState();
}

class _AddFoodDialogState extends State<AddFoodDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _kcal = TextEditingController();
  late MealType _meal = widget.initialMeal;

  @override
  void dispose() {
    _name.dispose();
    _kcal.dispose();
    super.dispose();
  }

  static String? _validateCalories(String? v) {
    final n = double.tryParse(v?.trim() ?? '');
    if (n == null) return 'กรุณากรอกเป็นตัวเลข';
    if (n < 0 || n > FoodEntry.maxCalories) return 'ต้องอยู่ระหว่าง 0–5000';
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop((
      name: _name.text,
      calories: double.parse(_kcal.text.trim()),
      meal: _meal,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('เพิ่มอาหาร'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const Key('foodNameField'),
              controller: _name,
              decoration: const InputDecoration(labelText: 'ชื่ออาหาร'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'กรุณากรอกชื่ออาหาร' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('caloriesField'),
              controller: _kcal,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'แคลอรี่ (kcal)'),
              validator: _validateCalories,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in MealType.values)
                  ChoiceChip(
                    label: Text(m.label),
                    selected: _meal == m,
                    onSelected: (_) => setState(() => _meal = m),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ยกเลิก'),
        ),
        FilledButton(
          key: const Key('saveFoodButton'),
          // theme ตั้งปุ่มให้กว้างเต็มจอ — ในกล่องนี้ต้องกำหนดขนาดเอง
          style: FilledButton.styleFrom(minimumSize: const Size(88, 48)),
          onPressed: _submit,
          child: const Text('บันทึก'),
        ),
      ],
    );
  }
}
