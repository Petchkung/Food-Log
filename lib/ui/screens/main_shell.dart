import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../state/food_log_controller.dart';
import 'add_food_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'scanner_screen.dart';
import 'stats_screen.dart';

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
          HomeScreen(
            user: widget.user,
            auth: widget.auth,
            onOpenStats: () => setState(() => _index = 2), // ปุ่ม "ดูสถิติ"
          ),
          const AddFoodScreen(key: Key('logTab')),
          const StatsScreen(key: Key('statsTab')),
          ProfileScreen(
            key: const Key('profileTab'),
            user: widget.user,
            auth: widget.auth,
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        key: const Key('scanButton'),
        heroTag: null,
        tooltip: 'สแกนอาหาร',
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onPressed: () {
          // หน้าที่ push อยู่เหนือ Provider จึงส่ง controller ต่อให้
          final controller = context.read<FoodLogController>();
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ChangeNotifierProvider<FoodLogController>.value(
                value: controller,
                child: const ScannerScreen(),
              ),
            ),
          );
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
