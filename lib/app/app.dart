import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/food_repository.dart';
import '../services/auth_service.dart';
import '../state/food_log_controller.dart';
import '../ui/screens/home_screen.dart';
import '../ui/screens/login_screen.dart';
import 'theme.dart';

class FoodLogApp extends StatelessWidget {
  const FoodLogApp({super.key, required this.auth, required this.repository});

  /// ส่งของจริงตอนรันแอป หรือของปลอมตอนเทสต์
  final AuthService auth;
  final FoodRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Log',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: AuthGate(auth: auth, repository: repository),
    );
  }
}

/// ยังไม่ล็อกอิน → หน้า Login, ล็อกอินแล้ว → หน้าหลัก (พร้อม Controller ของผู้ใช้คนนั้น)
class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.auth, required this.repository});

  final AuthService auth;
  final FoodRepository repository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: auth.authStateChanges(),
      initialData: auth.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) return LoginScreen(auth: auth);
        return ChangeNotifierProvider<FoodLogController>(
          key: ValueKey(user.uid), // เปลี่ยนผู้ใช้ = สร้าง Controller ใหม่
          create: (_) =>
              FoodLogController(repository: repository, uid: user.uid)..init(),
          child: HomeScreen(user: user, auth: auth),
        );
      },
    );
  }
}