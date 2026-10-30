import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import 'home_screen.dart';

/// โครงหลักหลังล็อกอิน: เมนูล่าง 4 แท็บ + ปุ่มสแกนตรงกลาง
class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.user, required this.auth});

  final AppUser user;
  final AuthService auth;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      // IndexedStack เก็บสถานะของแต่ละแท็บไว้ สลับไปมาแล้วหน้าไม่รีเซ็ต
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(user: widget.user, auth: widget.auth),
          const _PlaceholderTab(key: Key('logTab'), title: 'บันทึก'),
          const _PlaceholderTab(key: Key('statsTab'), title: 'สถิติ'),
          const _PlaceholderTab(key: Key('profileTab'), title: 'โปรไฟล์'),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        key: const Key('scanButton'),
        heroTag: null, // กันชนกับปุ่ม + ในหน้า Home ที่มี FAB อยู่แล้ว
        tooltip: 'สแกนอาหาร',
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onPressed: () {
          // TODO(เค้ก): ต่อหน้าสแกนอาหาร (feature/ai-scan)
        },
        child: const Icon(Icons.center_focus_strong_outlined),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            key: Key('navHome'),
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'หน้าหลัก',
          ),
          NavigationDestination(
            key: Key('navLog'),
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'บันทึก',
          ),
          NavigationDestination(
            key: Key('navStats'),
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'สถิติ',
          ),
          NavigationDestination(
            key: Key('navProfile'),
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'โปรไฟล์',
          ),
        ],
      ),
    );
  }
}

/// หน้าชั่วคราวของแท็บที่ยังไม่ได้ทำ (จะถูกแทนใน branch ถัด ๆ ไป)
class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Text(
          'หน้า$title\n(กำลังจัดทำ)',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
