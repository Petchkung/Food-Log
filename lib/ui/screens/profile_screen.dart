import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/thai_format.dart';
import '../../models/macro_targets.dart';
import '../../services/auth_service.dart';
import '../../state/food_log_controller.dart';

/// แท็บโปรไฟล์: ข้อมูลผู้ใช้ เป้าหมายแคลอรี่/สารอาหาร ซิงก์ และออกจากระบบ
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.user, required this.auth});

  final AppUser user;
  final AuthService auth;

  Future<void> _editGoal(BuildContext context, FoodLogController c) async {
    final goal = await showDialog<double>(
      context: context,
      builder: (_) => GoalDialog(initialGoal: c.goal),
    );
    if (goal == null) return;
    await c.setGoal(goal);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<FoodLogController>();
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final name = ThaiFormat.nameFromEmail(user.email);
    final targets = MacroTargets.fromCalories(c.goal);

    final syncStatus = c.syncing
        ? 'กำลังซิงก์'
        : c.pendingCount > 0
            ? 'รอซิงก์ ${c.pendingCount}'
            : 'ซิงก์แล้ว';

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                child: Text(
                  ThaiFormat.initial(name),
                  style:
                      text.headlineSmall?.copyWith(color: scheme.onPrimary),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      key: const Key('profileName'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      user.email,
                      key: const Key('profileEmail'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            color: scheme.primaryContainer,
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'เป้าหมายของฉัน',
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          label: 'แคลอรี่/วัน',
                          value: ThaiFormat.number(c.goal),
                          valueKey: 'profileGoal',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatTile(
                          label: 'โปรตีน (g)',
                          value: ThaiFormat.number(targets.protein),
                          valueKey: 'profileProtein',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatTile(
                          label: 'คาร์บ (g)',
                          value: ThaiFormat.number(targets.carbs),
                          valueKey: 'profileCarbs',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatTile(
                          label: 'ไขมัน (g)',
                          value: ThaiFormat.number(targets.fat),
                          valueKey: 'profileFat',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  key: const Key('editGoalButton'),
                  leading: const Icon(Icons.flag_outlined),
                  title: const Text('แก้เป้าหมายแคลอรี่'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _editGoal(context, c),
                ),
                const Divider(height: 1),
                ListTile(
                  key: const Key('profileSyncButton'),
                  leading: const Icon(Icons.cloud_outlined),
                  title: const Text('ซิงก์ข้อมูลกับ Cloud'),
                  trailing: Text(
                    syncStatus,
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  enabled: !c.syncing,
                  onTap: () => c.sync(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            key: const Key('profileSignOutButton'),
            onPressed: auth.signOut,
            icon: const Icon(Icons.logout),
            label: const Text('ออกจากระบบ'),
            style: OutlinedButton.styleFrom(
              foregroundColor: scheme.error,
              side: BorderSide(color: scheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.valueKey,
  });

  final String label;
  final String value;
  final String valueKey;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style:
                  text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              key: Key(valueKey),
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// กล่องตั้งเป้าแคลอรี่ต่อวัน: Slider 800–6000 ทีละ 100
class GoalDialog extends StatefulWidget {
  const GoalDialog({super.key, required this.initialGoal});

  final double initialGoal;

  static const double min = 800;
  static const double max = 6000;

  @override
  State<GoalDialog> createState() => _GoalDialogState();
}

class _GoalDialogState extends State<GoalDialog> {
  late double _value = ((widget.initialGoal / 100).round() * 100)
      .clamp(GoalDialog.min, GoalDialog.max)
      .toDouble();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AlertDialog(
      title: const Text('เป้าหมายแคลอรี่ต่อวัน'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${ThaiFormat.number(_value)} kcal',
            key: const Key('goalValueText'),
            style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          Slider(
            key: const Key('goalSlider'),
            min: GoalDialog.min,
            max: GoalDialog.max,
            divisions: 52,
            value: _value,
            label: ThaiFormat.number(_value),
            onChanged: (v) => setState(() => _value = v),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('800', style: text.bodySmall),
              Text('6,000', style: text.bodySmall),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ยกเลิก'),
        ),
        FilledButton(
          key: const Key('saveGoalButton'),
          // theme ตั้งปุ่มให้กว้างเต็มจอ — ในกล่องนี้ต้องกำหนดขนาดเอง
          style: FilledButton.styleFrom(minimumSize: const Size(88, 48)),
          onPressed: () => Navigator.of(context).pop(_value),
          child: const Text('บันทึก'),
        ),
      ],
    );
  }
}