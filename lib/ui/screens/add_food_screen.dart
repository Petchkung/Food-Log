import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/food_entry.dart';
import '../../models/meal_type.dart';
import '../../models/nutrition_info.dart';
import '../../services/food_api_service.dart';
import '../../state/food_log_controller.dart';
import 'manual_food_screen.dart';

/// หน้าเพิ่มอาหาร: ค้นจากฐานข้อมูล (Open Food Facts) / เลือกจากรายการล่าสุด / สร้างเอง
/// ใช้เป็นแท็บ "บันทึก" และเปิดจากปุ่ม + ในหน้าหลักได้
class AddFoodScreen extends StatefulWidget {
  const AddFoodScreen({super.key, this.initialMeal});

  /// มื้อที่เลือกไว้ให้ตอนเปิด (ถ้าไม่ส่งมา เดาจากเวลาปัจจุบัน)
  final MealType? initialMeal;

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final _search = TextEditingController();

  List<NutritionInfo> _results = const [];
  List<FoodEntry> _recent = const [];
  bool _searched = false; // เคยค้นแล้ว (ใช้แยก "ยังไม่ค้น" กับ "ค้นแล้วไม่เจอ")
  bool _loading = false;
  bool _showRecent = true;
  String? _error;
  int _requestId = 0; // กันผลค้นหาเก่ามาทับผลใหม่
  FoodLogController? _controller;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ฟัง controller เพื่ออัปเดตรายการล่าสุดเมื่อมีการเพิ่ม/ลบอาหาร
    _controller = Provider.of<FoodLogController>(context);
    _loadRecent();
  }

  MealType get _defaultMeal =>
      widget.initialMeal ?? MealType.suggestFor(_controller!.now());

  Future<void> _loadRecent() async {
    final c = _controller!;
    final today = c.now();
    final from = DateTime(today.year, today.month, today.day - 14);
    final to = DateTime(today.year, today.month, today.day);
    final list = [...await c.repository.entriesForRange(c.uid, from, to)];
    if (!mounted) return;
    list.sort((a, b) => b.eatenAt.compareTo(a.eatenAt));
    final seen = <String>{};
    final recent = <FoodEntry>[];
    for (final e in list) {
      if (seen.add(e.name.toLowerCase())) recent.add(e);
      if (recent.length >= 10) break;
    }
    setState(() => _recent = recent);
  }

  Future<void> _runSearch() async {
    final q = _search.text.trim();
    FocusScope.of(context).unfocus();
    if (q.length < 2) {
      setState(() {
        _searched = false;
        _results = const [];
        _error = 'พิมพ์ชื่ออาหารอย่างน้อย 2 ตัวอักษร';
      });
      return;
    }

    final api = context.read<FoodApiService>();
    final id = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final found = await api.search(q);
      if (!mounted || id != _requestId) return;
      setState(() {
        _results = found;
        _searched = true;
        _loading = false;
      });
    } on FoodApiException catch (e) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _results = const [];
        _searched = false;
        _loading = false;
        _error = e.message;
      });
    }
  }

  void _onQueryChanged(String value) {
    if (value.trim().isEmpty) {
      _requestId++; // ยกเลิกผลที่ยังค้างอยู่
      setState(() {
        _results = const [];
        _searched = false;
        _loading = false;
        _error = null;
      });
    }
  }

  /// เลือกปริมาณ + มื้อ แล้วบันทึก
  Future<void> _pick(NutritionInfo info, {required bool allowGrams}) async {
    final picked = await showModalBottomSheet<({NutritionInfo info, MealType meal})>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _PortionSheet(
        info: info,
        initialMeal: _defaultMeal,
        allowGrams: allowGrams,
      ),
    );
    if (picked == null || !mounted) return;
    await _save(
      name: picked.info.name,
      calories: picked.info.calories,
      protein: picked.info.protein,
      carbs: picked.info.carbs,
      fat: picked.info.fat,
      meal: picked.meal,
    );
  }

  Future<void> _openManual() async {
    final r = await Navigator.of(context).push<ManualFood>(
      MaterialPageRoute(
        builder: (_) => ManualFoodScreen(initialMeal: _defaultMeal),
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

  Future<void> _save({
    required String name,
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
    required MealType meal,
  }) async {
    final navigator = Navigator.of(context);
    await _controller!.addEntry(
      name: name,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      mealType: meal,
    );
    if (!mounted) return;
    _search.clear();
    setState(() {
      _results = const [];
      _searched = false;
      _error = null;
    });
    // เปิดจากปุ่ม + ในหน้าหลัก → ปิดหน้านี้ / อยู่ในแท็บ "บันทึก" → อยู่หน้าเดิม
    if (navigator.canPop()) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final List<Widget> body;
    if (_loading) {
      body = const [
        Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: CircularProgressIndicator(key: Key('searchLoading')),
          ),
        ),
      ];
    } else if (_error != null) {
      body = [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            key: const Key('searchError'),
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.error),
          ),
        ),
      ];
    } else if (_searched) {
      body = _results.isEmpty
          ? const [
              Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'ไม่พบอาหารที่ค้นหา ลองคำอื่น หรือกด "สร้างอาหารเอง"',
                  key: Key('noResults'),
                  textAlign: TextAlign.center,
                ),
              ),
            ]
          : [
              for (var i = 0; i < _results.length; i++)
                ListTile(
                  key: ValueKey('result-$i'),
                  leading: const Icon(Icons.restaurant_outlined),
                  title: Text(_results[i].name),
                  subtitle: Text(
                    [
                      if (_results[i].brand != null) _results[i].brand!,
                      '${_results[i].calories.round()} kcal / 100 g',
                    ].join(' · '),
                  ),
                  onTap: () => _pick(_results[i], allowGrams: true),
                ),
            ];
    } else if (_showRecent) {
      body = _recent.isEmpty
          ? const [
              Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'ยังไม่มีรายการล่าสุด ลองค้นหาอาหารด้านบน',
                  key: Key('recentEmpty'),
                  textAlign: TextAlign.center,
                ),
              ),
            ]
          : [
              for (final e in _recent)
                ListTile(
                  key: ValueKey('recent-${e.id}'),
                  leading: Icon(e.mealType.icon),
                  title: Text(e.name),
                  subtitle: Text('${e.calories.round()} kcal'),
                  trailing: const Icon(Icons.add_circle_outline),
                  onTap: () => _pick(
                    NutritionInfo(
                      name: e.name,
                      calories: e.calories,
                      protein: e.protein,
                      carbs: e.carbs,
                      fat: e.fat,
                    ),
                    allowGrams: false,
                  ),
                ),
            ];
    } else {
      body = const [];
    }

    return Scaffold(
      appBar: AppBar(title: const Text('เพิ่มอาหาร')),
      body: SafeArea(
        child: ListView(
          // เว้นล่างให้พ้นปุ่มสแกนกลางเมนู
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            SearchBar(
              key: const Key('foodSearchBar'),
              controller: _search,
              hintText: 'ค้นหาอาหาร เช่น ข้าวมันไก่',
              leading: const Icon(Icons.search),
              onChanged: _onQueryChanged,
              onSubmitted: (_) => _runSearch(),
              trailing: [
                IconButton(
                  key: const Key('searchButton'),
                  tooltip: 'ค้นหา',
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _runSearch,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  key: const Key('recentChip'),
                  label: const Text('ล่าสุด'),
                  selected: _showRecent,
                  onSelected: (v) => setState(() => _showRecent = v),
                ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const Key('manualFoodButton'),
              onPressed: _openManual,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('สร้างอาหารเอง'),
            ),
            const SizedBox(height: 8),
            ...body,
          ],
        ),
      ),
    );
  }
}

/// แผ่นล่างเลือกปริมาณ (กรัม) + มื้อ ก่อนบันทึก
class _PortionSheet extends StatefulWidget {
  const _PortionSheet({
    required this.info,
    required this.initialMeal,
    required this.allowGrams,
  });

  final NutritionInfo info;
  final MealType initialMeal;

  /// false = รายการล่าสุด (บันทึกเป็น 1 ที่เท่าเดิม ไม่ปรับกรัม)
  final bool allowGrams;

  @override
  State<_PortionSheet> createState() => _PortionSheetState();
}

class _PortionSheetState extends State<_PortionSheet> {
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

  bool get _valid => !widget.allowGrams || _gramsValue != null;

  NutritionInfo get _scaled {
    final g = _gramsValue;
    if (!widget.allowGrams || g == null) return widget.info;
    return widget.info.scaledTo(g);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final n = _scaled;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        key: const Key('portionSheet'),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.info.name, style: text.titleLarge),
            const SizedBox(height: 4),
            Text(
              '${n.calories.round()} kcal',
              key: const Key('previewCalories'),
              style: text.headlineSmall,
            ),
            Text(
              'โปรตีน ${n.protein.round()} g · คาร์บ ${n.carbs.round()} g · ไขมัน ${n.fat.round()} g',
              key: const Key('previewMacros'),
              style: text.bodyMedium,
            ),
            if (widget.allowGrams) ...[
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
            ],
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
              key: const Key('confirmAddButton'),
              onPressed: _valid
                  ? () => Navigator.of(context).pop((info: n, meal: _meal))
                  : null,
              child: const Text('เพิ่มลงมื้ออาหาร'),
            ),
          ],
        ),
      ),
    );
  }
}