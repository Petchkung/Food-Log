import 'package:flutter/material.dart';

import '../../core/thai_format.dart';

/// ส่วนหัวหน้าหลัก: วันที่ + คำทักทาย + ชิปซิงก์ + อวาตาร์
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.day,
    required this.name,
    required this.syncing,
    required this.pendingCount,
    required this.onSync,
    required this.onSignOut,
  });

  final DateTime day;
  final String name;
  final bool syncing;
  final int pendingCount;
  final VoidCallback onSync;

  /// ชั่วคราว: จะย้ายไปหน้าโปรไฟล์ใน feature/profile-screen
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

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

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ThaiFormat.date(day),
                key: const Key('homeDate'),
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Text(
                'สวัสดี, $name',
                key: const Key('homeGreeting'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        ActionChip(
          key: const Key('syncButton'),
          avatar: Icon(syncIcon, size: 18, color: scheme.onPrimaryContainer),
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
        IconButton(
          key: const Key('signOutButton'),
          tooltip: 'ออกจากระบบ',
          icon: const Icon(Icons.logout),
          onPressed: onSignOut,
        ),
      ],
    );
  }
}
