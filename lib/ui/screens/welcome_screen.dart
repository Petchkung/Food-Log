import 'package:flutter/material.dart';

/// หน้าแรกก่อนล็อกอิน (Welcome) ตามดีไซน์ Food Log UI
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    required this.onStart,
    required this.onLogin,
  });

  /// กด "เริ่มต้นใช้งาน"
  final VoidCallback onStart;

  /// กด "มีบัญชีแล้ว? เข้าสู่ระบบ"
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _Logo(),
                  const SizedBox(height: 24),
                  const _HeroCard(),
                  const SizedBox(height: 28),
                  Text(
                    'สแกนอาหาร\nรู้แคลอรี่ทันที',
                    key: const Key('welcomeTitle'),
                    style: text.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ถ่ายรูปมื้ออาหาร แล้วดูแคลอรี่และสารอาหารได้ในไม่กี่วินาที',
                    style: text.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const _PageDots(count: 3, index: 0),
                  const SizedBox(height: 32),
                  FilledButton(
                    key: const Key('welcomeStartButton'),
                    onPressed: onStart,
                    child: const Text('เริ่มต้นใช้งาน'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    key: const Key('welcomeLoginButton'),
                    onPressed: onLogin,
                    child: const Text('มีบัญชีแล้ว? เข้าสู่ระบบ'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// โลโก้ใบไม้ + ชื่อแอป
class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.eco_outlined, color: scheme.onPrimary, size: 22),
        ),
        const SizedBox(width: 12),
        Text(
          'Food Log',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

/// การ์ดภาพประกอบ: กรอบสแกน + จานอาหาร + การ์ดผลลัพธ์ลอย
class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 1.03,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _ScanFramePainter(scheme.primary)),
            ),
            const Center(
              child: FractionallySizedBox(
                widthFactor: 0.76,
                child: AspectRatio(aspectRatio: 1, child: _Plate()),
              ),
            ),
            const Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 0, 28),
                child: _ResultChip(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// จานวงกลมซ้อนกัน + ไอคอนชามอาหาร
class _Plate extends StatelessWidget {
  const _Plate();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.76,
          heightFactor: 0.76,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.tertiaryContainer,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.ramen_dining_outlined,
                size: 56,
                color: scheme.tertiary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// การ์ดลอย "ข้าวมันไก่ / 520 kcal · AI มั่นใจ 86%"
class _ResultChip extends StatelessWidget {
  const _ResultChip();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Material(
      elevation: 4,
      shadowColor: scheme.shadow,
      color: scheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.auto_awesome,
                size: 22,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ข้าวมันไก่',
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  '520 kcal · AI มั่นใจ 86%',
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// จุด indicator (จุดที่ active เป็นแถบยาว)
class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 8),
            width: i == index ? 28 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == index ? scheme.primary : scheme.outlineVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}

/// วาดกรอบมุมสแกน 4 มุม
class _ScanFramePainter extends CustomPainter {
  _ScanFramePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const inset = 16.0; // ระยะจากขอบการ์ด
    const arm = 48.0; // ความยาวแขนของมุม
    const r = 16.0; // ความโค้งของมุม
    const radius = Radius.circular(r);
    final l = inset, t = inset;
    final rt = size.width - inset, b = size.height - inset;

    final path = Path()
      // มุมบนซ้าย
      ..moveTo(l + arm, t)
      ..lineTo(l + r, t)
      ..arcToPoint(Offset(l, t + r), radius: radius, clockwise: false)
      ..lineTo(l, t + arm)
      // มุมบนขวา
      ..moveTo(rt - arm, t)
      ..lineTo(rt - r, t)
      ..arcToPoint(Offset(rt, t + r), radius: radius)
      ..lineTo(rt, t + arm)
      // มุมล่างขวา
      ..moveTo(rt, b - arm)
      ..lineTo(rt, b - r)
      ..arcToPoint(Offset(rt - r, b), radius: radius)
      ..lineTo(rt - arm, b)
      // มุมล่างซ้าย
      ..moveTo(l + arm, b)
      ..lineTo(l + r, b)
      ..arcToPoint(Offset(l, b - r), radius: radius)
      ..lineTo(l, b - arm);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ScanFramePainter old) => old.color != color;
}
