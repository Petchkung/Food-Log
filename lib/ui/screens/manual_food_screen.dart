import 'package:flutter/material.dart';

import '../../models/food_entry.dart';
import '../../models/meal_type.dart';
import '../../models/nutrition_info.dart';

/// ผลที่ได้จากฟอร์มสร้างอาหารเอง
typedef ManualFood = ({
  String name,
  double calories,
  double protein,
  double carbs,
  double fat,
  MealType meal,
});

/// ฟอร์มสร้างอาหารเอง: ชื่อ + kcal + โปรตีน/คาร์บ/ไขมัน (กดบันทึกแล้วส่งค่ากลับให้หน้าที่เรียก)
class ManualFoodScreen extends StatefulWidget {
  const ManualFoodScreen({super.key, required this.initialMeal, this.initial});

  final MealType initialMeal;

  /// ค่าตั้งต้นในฟอร์ม (เช่น ผลจาก AI ที่ผู้ใช้อยากแก้) — ไม่ส่งมา = ฟอร์มว่าง
  final NutritionInfo? initial;

  @override
  State<ManualFoodScreen> createState() => _ManualFoodScreenState();
}

class _ManualFoodScreenState extends State<ManualFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial?.name);
  late final _kcal = TextEditingController(text: _fmt(widget.initial?.calories));
  late final _protein = TextEditingController(text: _fmt(widget.initial?.protein));
  late final _carbs = TextEditingController(text: _fmt(widget.initial?.carbs));
  late final _fat = TextEditingController(text: _fmt(widget.initial?.fat));
  late MealType _meal = widget.initialMeal;

  @override
  void dispose() {
    _name.dispose();
    _kcal.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    super.dispose();
  }

  /// แสดงตัวเลขในช่อง: เต็มจำนวนไม่มีทศนิยม ไม่งั้น 1 ตำแหน่ง (ไม่มีค่า = ช่องว่าง)
  static String _fmt(double? v) {
    if (v == null) return '';
    return v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);
  }

  static String? _validateCalories(String? v) {
    final n = double.tryParse(v?.trim() ?? '');
    if (n == null) return 'กรุณากรอกเป็นตัวเลข';
    if (n < 0 || n > FoodEntry.maxCalories) return 'ต้องอยู่ระหว่าง 0–5000';
    return null;
  }

  /// สารอาหารเว้นว่างได้ (นับเป็น 0)
  static String? _validateMacro(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return null;
    final n = double.tryParse(t);
    if (n == null) return 'กรุณากรอกเป็นตัวเลข';
    if (n < 0 || n > FoodEntry.maxGrams) return 'ต้องอยู่ระหว่าง 0–1000';
    return null;
  }

  static double _macro(TextEditingController c) =>
      double.tryParse(c.text.trim()) ?? 0;

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop<ManualFood>((
      name: _name.text,
      calories: double.parse(_kcal.text.trim()),
      protein: _macro(_protein),
      carbs: _macro(_carbs),
      fat: _macro(_fat),
      meal: _meal,
    ));
  }

  Widget _numberField({
    required Key key,
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      key: key,
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('สร้างอาหารเอง')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                key: const Key('foodNameField'),
                controller: _name,
                decoration: const InputDecoration(labelText: 'ชื่ออาหาร'),
                validator: (v) => (v == null || FoodEntry.cleanName(v).isEmpty)
                    ? 'กรุณากรอกชื่ออาหาร'
                    : null,
              ),
              const SizedBox(height: 12),
              _numberField(
                key: const Key('caloriesField'),
                controller: _kcal,
                label: 'แคลอรี่ (kcal)',
                validator: _validateCalories,
              ),
              const SizedBox(height: 12),
              _numberField(
                key: const Key('proteinField'),
                controller: _protein,
                label: 'โปรตีน (g) — ไม่บังคับ',
                validator: _validateMacro,
              ),
              const SizedBox(height: 12),
              _numberField(
                key: const Key('carbsField'),
                controller: _carbs,
                label: 'คาร์บ (g) — ไม่บังคับ',
                validator: _validateMacro,
              ),
              const SizedBox(height: 12),
              _numberField(
                key: const Key('fatField'),
                controller: _fat,
                label: 'ไขมัน (g) — ไม่บังคับ',
                validator: _validateMacro,
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
                key: const Key('saveFoodButton'),
                onPressed: _submit,
                child: const Text('บันทึก'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}