import 'package:flutter/material.dart';

import '../../core/thai_format.dart';

/// ส่วนหัวหน้าหลัก: วันที่ (พร้อมลูกศรเปลี่ยนวัน) + คำทักทาย + ชิปซิงก์ + อวาตาร์
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.day,
    required this.name,
    required this.syncing,
    required this.pendingCount,
    required this.onSync,
    this.onSignOut,
    this.onPreviousDay,
    this.onNextDay,
  });

  final DateTime day;
  final String name;
  final bool syncing;
  final int pendingCount;
  final VoidCallback onSync;

  /// ถ้าไม่ส่ง จะไม่แสดงปุ่มออกจากระบบ (ตอนนี้ปุ่มนี้อยู่ในหน้าโปรไฟล์)
  final VoidCallback? onSignOut;

  /// ถ้าไม่ส่ง onPreviousDay จะไม่แสดงลูกศร / onNextDay เป็น null = กดวันถัดไปไม่ได้
  final VoidCallback? onPreviousDay;
  final VoidCallback? onNextDay;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final showArrows = onPreviousDay != null;

    final syncLabel = syncing
        ? 'กำลังซิงก์'
        : pendingCount > 0
        ? 'รอซิงก์ $pendingCount'
        : 'ซิงก์แล้ว';
    final syncIcon = syncing
        ? Icons.cloud_sync_outlined
        : pendingCount > 0
        ? Icons.cloud_upload_outlined
        : Icons.cloud_done_outlined;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // แถวบน: ลูกศรเปลี่ยนวัน + วันที่
        Row(
          children: [
            if (showArrows)
              IconButton(
                key: const Key('prevDayButton'),
                tooltip: 'วันก่อนหน้า',
                visualDensity: VisualDensity.compact,
                iconSize: 22,
                icon: const Icon(Icons.chevron_left),
                onPressed: onPreviousDay,
              ),
            Flexible(
              child: Text(
                ThaiFormat.date(day),
                key: const Key('homeDate'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            if (showArrows)
              IconButton(
                key: const Key('nextDayButton'),
                tooltip: 'วันถัดไป',
                visualDensity: VisualDensity.compact,
                iconSize: 22,
                icon: const Icon(Icons.chevron_right),
                onPressed: onNextDay,
              ),
          ],
        ),
        // แถวล่าง: คำทักทาย + ชิปซิงก์ + อวาตาร์ (+ ออกจากระบบ ถ้ามี)
        Row(
          children: [
            Expanded(
              child: Text(
                'สวัสดี, $name',
                key: const Key('homeGreeting'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ActionChip(
              key: const Key('syncButton'),
              avatar: Icon(
                syncIcon,
                size: 18,
                color: scheme.onPrimaryContainer,
              ),
              label: Text(syncLabel),
              labelStyle: TextStyle(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
              backgroundColor: scheme.primaryContainer,
              side: BorderSide.none,
              onPressed: syncing ? null : onSync,
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              key: const Key('homeAvatar'),
              radius: 20,
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
              child: Text(ThaiFormat.initial(name)),
            ),
            if (onSignOut != null)
              IconButton(
                key: const Key('signOutButton'),
                tooltip: 'ออกจากระบบ',
                icon: const Icon(Icons.logout),
                onPressed: onSignOut,
              ),
          ],
        ),
      ],
    );
  }
}
