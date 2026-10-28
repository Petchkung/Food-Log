// สรุป coverage จาก coverage/lcov.info
// ใช้: flutter test --coverage แล้ว dart run tool/coverage.dart 70
import 'dart:io';

/// ไฟล์ที่ไม่นับ: ไฟล์ที่ระบบสร้างให้ และไฟล์ที่คุยกับ Firebase จริงโดยตรง
/// (ทดสอบผ่าน interface + ของปลอมแทน)
const excluded = [
  'lib/firebase_options.dart',
  'lib/main.dart',
  'lib/services/firebase_auth_service.dart',
  'lib/services/firestore_sync_service.dart',
];

void main(List<String> args) {
  final minPercent = args.isNotEmpty ? double.parse(args.first) : 70.0;
  final file = File('coverage/lcov.info');
  if (!file.existsSync()) {
    stderr.writeln('ไม่พบ coverage/lcov.info — รัน flutter test --coverage ก่อน');
    exit(1);
  }

  // อ่านทีละไฟล์: SF = ชื่อไฟล์, DA = บรรทัด + จำนวนครั้งที่รัน
  final results = <String, (int hit, int found)>{};
  String? current;
  var hit = 0, found = 0;
  for (final line in file.readAsLinesSync()) {
    if (line.startsWith('SF:')) {
      current = line.substring(3).replaceAll(r'\', '/');
      hit = 0;
      found = 0;
    } else if (line.startsWith('DA:')) {
      found++;
      if (int.parse(line.substring(3).split(',')[1]) > 0) hit++;
    } else if (line == 'end_of_record' && current != null) {
      if (!excluded.any(current.endsWith)) results[current] = (hit, found);
      current = null;
    }
  }

  var totalHit = 0, totalFound = 0;
  final rows = results.entries.toList()
    ..sort((a, b) => _pct(a.value.$1, a.value.$2).compareTo(_pct(b.value.$1, b.value.$2)));
  stdout.writeln('Coverage ต่อไฟล์ (น้อยสุดก่อน):');
  for (final r in rows) {
    final (h, f) = r.value;
    totalHit += h;
    totalFound += f;
    stdout.writeln('  ${_pct(h, f).toStringAsFixed(1).padLeft(5)}%  $h/$f  ${r.key}');
  }

  final total = _pct(totalHit, totalFound);
  stdout.writeln('\nรวม: ${total.toStringAsFixed(1)}% ($totalHit/$totalFound บรรทัด) — ขั้นต่ำ $minPercent%');
  if (total < minPercent) {
    stderr.writeln('❌ coverage ต่ำกว่าเกณฑ์');
    exit(1);
  }
  stdout.writeln('✅ ผ่านเกณฑ์');
}

double _pct(int hit, int found) => found == 0 ? 100 : hit * 100 / found;