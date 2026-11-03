import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/meal_type.dart';
import '../../models/nutrition_info.dart';
import '../../state/food_log_controller.dart';
import 'manual_food_screen.dart';

/// ผลวิเคราะห์จาก AI: ปรับปริมาณ/มื้อได้ แล้วเพิ่มลงมื้ออาหาร หรือแก้ไขเองถ้า AI เดาผิด
class ScanResultScreen extends StatefulWidget {
  const ScanResultScreen({
    super.key,
    required this.info,
    required this.initialMeal,
  });

  final NutritionInfo info;
  final MealType initialMeal;

  /// ต่ำกว่านี้แสดงคำเตือนให้ตรวจก่อนเพิ่ม
  static const double lowConfidence = 0.5;

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  late final TextEditingController _grams = TextEditingController(
    text: widget.info.servingGrams.round().toString(),
  );
  late MealType _meal = widget.initialMeal;

  @override
  void dispose() {
    _grams.dispose();
    super.dispose();
  }

  double? get _gramsValue {
    final g = double.tryParse(_grams.text.trim());
    if (g == null || g <= 0 || g > 5000) return null;
    return g;
  }

  NutritionInfo get _scaled {
    final g = _gramsValue;
    return g == null ? widget.info : widget.info.scaledTo(g);
  }

  Future<void> _save({
    required String name,
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
    required MealType meal,
  }) async {
    final navigator = Navigator.of(context);
    await context.read<FoodLogController>().addEntry(
      name: name,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      mealType: meal,
    );
    if (!mounted) return;
    navigator.popUntil((route) => route.isFirst); // กลับหน้าหลัก
  }

  Future<void> _add() {
    final n = _scaled;
    return _save(
      name: n.name,
      calories: n.calories,
      protein: n.protein,
      carbs: n.carbs,
      fat: n.fat,
      meal: _meal,
    );
  }

  Future<void> _editManually() async {
    final r = await Navigator.of(context).push<ManualFood>(
      MaterialPageRoute(
        builder: (_) => ManualFoodScreen(initialMeal: _meal, initial: _scaled),
      ),
    );
    if (r == null || !mounted) return;
    await _save(
      name: r.name,
      calories: r.calories,
      protein: r.protein,
      carbs: r.carbs,
      fat: r.fat,
      meal: r.meal,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final n = _scaled;
    final confidence = widget.info.confidence;

    return Scaffold(
      key: const Key('scanResultScreen'),
      appBar: AppBar(title: const Text('ผลวิเคราะห์ด้วย AI')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.info.name,
                      key: const Key('scanName'),
                      style: text.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${n.calories.round()} kcal',
                      key: const Key('scanCalories'),
                      style: text.headlineMedium?.copyWith(color: scheme.primary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'โปรตีน ${n.protein.round()} g · คาร์บ ${n.carbs.round()} g · ไขมัน ${n.fat.round()} g',
                      key: const Key('scanMacros'),
                    ),
                  ],
                ),
              ),
            ),
            if (confidence != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('ความมั่นใจของ AI'),
                  const SizedBox(width: 12),
                  Expanded(child: LinearProgressIndicator(value: confidence)),
                  const SizedBox(width: 12),
                  Text(
                    '${(confidence * 100).round()}%',
                    key: const Key('scanConfidence'),
                  ),
                ],
              ),
              if (confidence < ScanResultScreen.lowConfidence)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'AI ไม่ค่อยมั่นใจ กรุณาตรวจสอบค่าก่อนเพิ่ม',
                    key: const Key('lowConfidenceWarning'),
                    style: TextStyle(color: scheme.error),
                  ),
                ),
            ],
            const SizedBox(height: 16),
            TextField(
              key: const Key('gramsField'),
              controller: _grams,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'ปริมาณ (กรัม)',
                errorText: _gramsValue == null ? 'กรอกตัวเลข 1–5000' : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('addScanButton'),
              onPressed: _gramsValue == null ? null : _add,
              child: const Text('เพิ่มลงมื้ออาหาร'),
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const Key('editManualButton'),
              onPressed: _editManually,
              child: const Text('ไม่ใช่รายการนี้? แก้ไขเอง'),
            ),
          ],
        ),
      ),
    );
  }
}