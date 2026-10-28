import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../ui/screens/home_screen.dart';
import '../ui/screens/login_screen.dart';
import 'theme.dart';

class FoodLogApp extends StatelessWidget {
  const FoodLogApp({super.key, required this.auth});

  /// ส่งของจริง (Firebase) ตอนรันแอป หรือของปลอม (Fake) ตอนเทสต์
  final AuthService auth;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Log',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: AuthGate(auth: auth),
    );
  }
}

/// ยังไม่ล็อกอิน → หน้า Login, ล็อกอินแล้ว → หน้าหลัก
class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.auth});

  final AuthService auth;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: auth.authStateChanges(),
      initialData: auth.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) return LoginScreen(auth: auth);
        return HomeScreen(user: user, auth: auth);
      },
    );
  }
}