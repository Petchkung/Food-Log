import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/meal_type.dart';
import '../../models/nutrition_info.dart';
import '../../services/ai_food_analyzer.dart';
import '../../services/photo_picker.dart';
import '../../state/food_log_controller.dart';
import 'scan_result_screen.dart';

/// หน้าสแกนอาหารด้วย AI: ถ่ายรูป / เลือกจากแกลเลอรี / พิมพ์บรรยาย → วิเคราะห์ → หน้าผลสแกน
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final _text = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<PickedPhoto?> _pick(PhotoSource source) async {
    final picker = context.read<PhotoPicker>();
    try {
      return await picker.pick(source);
    } on Exception {
      if (mounted) {
        setState(() => _error =
            'เปิดกล้องหรือแกลเลอรีไม่ได้ ตรวจสอบสิทธิ์การเข้าถึงในการตั้งค่าเครื่อง');
      }
      return null;
    }
  }

  Future<void> _fromPhoto(PhotoSource source) async {
    final ai = context.read<AiFoodAnalyzer>();
    setState(() => _error = null);
    final photo = await _pick(source);
    if (photo == null || !mounted) return; // ผู้ใช้ยกเลิก
    await _analyze(() => ai.analyzeImage(photo.bytes, photo.mimeType));
  }

  Future<void> _fromText() async {
    final description = _text.text.trim();
    if (description.isEmpty) {
      setState(() => _error = 'กรุณาบรรยายอาหาร เช่น "ข้าวผัดกุ้ง 1 จาน"');
      return;
    }
    FocusScope.of(context).unfocus();
    final ai = context.read<AiFoodAnalyzer>();
    await _analyze(() => ai.analyzeText(description));
  }

  Future<void> _analyze(Future<NutritionInfo> Function() run) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final info = await run();
      if (!mounted) return;
      setState(() => _busy = false);
      await _openResult(info);
    } on AiAnalysisException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
    }
  }

  Future<void> _openResult(NutritionInfo info) {
    final c = context.read<FoodLogController>();
    // หน้าที่ push อยู่เหนือ Provider จึงต้องส่ง controller ต่อให้
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider<FoodLogController>.value(
          value: c,
          child: ScanResultScreen(
            info: info,
            initialMeal: MealType.suggestFor(c.now()),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      key: const Key('scannerScreen'),
      appBar: AppBar(title: const Text('สแกนอาหาร')),
      body: SafeArea(
        child: _busy
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(key: Key('analyzingIndicator')),
                    const SizedBox(height: 16),
                    Text('AI กำลังวิเคราะห์อาหาร...', style: text.titleMedium),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Icon(
                    Icons.center_focus_strong_outlined,
                    size: 72,
                    color: scheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ถ่ายรูปอาหาร ให้ AI ประเมินแคลอรี่และสารอาหาร',
                    textAlign: TextAlign.center,
                    style: text.titleMedium,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    key: const Key('cameraButton'),
                    onPressed: () => _fromPhoto(PhotoSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('ถ่ายรูป'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    key: const Key('galleryButton'),
                    onPressed: () => _fromPhoto(PhotoSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('เลือกจากแกลเลอรี'),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'หรือบรรยายอาหารเป็นข้อความ',
                    style: text.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    key: const Key('describeField'),
                    controller: _text,
                    maxLength: AiFoodPrompt.maxDescriptionLength,
                    decoration: const InputDecoration(
                      hintText: 'เช่น ข้าวผัดกุ้ง 1 จาน ไข่ดาว 1 ฟอง',
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    key: const Key('textAnalyzeButton'),
                    onPressed: _fromText,
                    child: const Text('วิเคราะห์จากข้อความ'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      key: const Key('scanError'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.error),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}