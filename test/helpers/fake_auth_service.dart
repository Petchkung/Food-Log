import 'dart:async';

import 'package:food_log/services/auth_service.dart';

/// Auth ปลอมสำหรับเทสต์ — ไม่ต่อ Firebase จริง
class FakeAuthService implements AuthService {
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _user;

  /// ตั้งค่าเป็นรหัส error (เช่น 'invalid-credential') เพื่อจำลองการล็อกอินพลาด
  String? failWith;

  /// อีเมลที่ถูกขอรีเซ็ตรหัสผ่าน (ไว้ตรวจในเทสต์)
  final List<String> resetEmails = [];

  @override
  Stream<AppUser?> authStateChanges() => _controller.stream;

  @override
  AppUser? get currentUser => _user;

  Future<AppUser> _login(String email) async {
    if (failWith != null) throw AuthException.fromCode(failWith!);
    _user = AppUser(uid: 'test-uid', email: email.trim());
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<AppUser> signIn({required String email, required String password}) =>
      _login(email);

  @override
  Future<AppUser> signUp({required String email, required String password}) =>
      _login(email);

  @override
  Future<AppUser> signInWithGoogle() => _login('google.user@gmail.com');

  @override
  Future<void> sendPasswordReset(String email) async {
    if (failWith != null) throw AuthException.fromCode(failWith!);
    resetEmails.add(email.trim());
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }
}