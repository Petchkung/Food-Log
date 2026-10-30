import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/food_repository.dart';
import '../services/auth_service.dart';
import '../state/food_log_controller.dart';
import '../ui/screens/home_screen.dart';
import '../ui/screens/login_screen.dart';
import '../ui/screens/welcome_screen.dart';
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

/// ยังไม่ล็อกอิน → หน้า Welcome/Login, ล็อกอินแล้ว → หน้าหลัก (พร้อม Controller ของผู้ใช้คนนั้น)
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
        if (user == null) return _LoggedOutFlow(auth: auth);
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

/// ช่วงที่ยังไม่ล็อกอิน: เริ่มที่ Welcome แล้วกดไปหน้า Login ได้ (กดกลับมา Welcome ได้)
class _LoggedOutFlow extends StatefulWidget {
  const _LoggedOutFlow({required this.auth});

  final AuthService auth;

  @override
  State<_LoggedOutFlow> createState() => _LoggedOutFlowState();
}

class _LoggedOutFlowState extends State<_LoggedOutFlow> {
  bool _showLogin = false;
  bool _signUp = false;

  void _openLogin({required bool signUp}) => setState(() {
    _signUp = signUp;
    _showLogin = true;
  });

  void _backToWelcome() => setState(() => _showLogin = false);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // อยู่หน้า Login: ปุ่มย้อนกลับของเครื่องให้กลับ Welcome แทนการปิดแอป
      canPop: !_showLogin,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _backToWelcome();
      },
      child: _showLogin
          ? LoginScreen(
              auth: widget.auth,
              initialSignUp: _signUp,
              onBack: _backToWelcome,
            )
          : WelcomeScreen(
              onStart: () => _openLogin(signUp: true),
              onLogin: () => _openLogin(signUp: false),
            ),
    );
  }
}
