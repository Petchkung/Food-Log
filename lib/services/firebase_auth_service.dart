import 'package:firebase_auth/firebase_auth.dart' as fb;

import 'auth_service.dart';

/// ล็อกอินด้วย Firebase Authentication (อีเมล/รหัสผ่าน และ Google)
class FirebaseAuthService implements AuthService {
  FirebaseAuthService([fb.FirebaseAuth? auth])
      : _auth = auth ?? fb.FirebaseAuth.instance;

  final fb.FirebaseAuth _auth;

  AppUser? _toAppUser(fb.User? u) =>
      u == null ? null : AppUser(uid: u.uid, email: u.email ?? '');

  @override
  Stream<AppUser?> authStateChanges() =>
      _auth.authStateChanges().map(_toAppUser);

  @override
  AppUser? get currentUser => _toAppUser(_auth.currentUser);

  @override
  Future<AppUser> signIn({required String email, required String password}) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password);
      return _toAppUser(cred.user)!;
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException.fromCode(e.code);
    }
  }

  @override
  Future<AppUser> signUp({required String email, required String password}) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);
      return _toAppUser(cred.user)!;
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException.fromCode(e.code);
    }
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    try {
      // เปิดหน้าเลือกบัญชี Google ผ่านเบราว์เซอร์ในแอป — ไม่ต้องใช้แพ็กเกจเพิ่ม
      final cred = await _auth.signInWithProvider(fb.GoogleAuthProvider());
      return _toAppUser(cred.user)!;
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException.fromCode(e.code);
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on fb.FirebaseAuthException catch (e) {
      // ไม่บอกว่าอีเมลนี้มีบัญชีหรือไม่ (กันคนสุ่มเดาอีเมลในระบบ)
      if (e.code == 'user-not-found') return;
      throw AuthException.fromCode(e.code);
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();
}