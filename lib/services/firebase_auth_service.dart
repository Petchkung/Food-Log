import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_service.dart';

/// ล็อกอินด้วย Firebase Authentication (อีเมล/รหัสผ่าน และ Google)
class FirebaseAuthService implements AuthService {
  FirebaseAuthService([fb.FirebaseAuth? auth])
      : _auth = auth ?? fb.FirebaseAuth.instance;

  final fb.FirebaseAuth _auth;

  /// GoogleSignIn ต้อง initialize ครั้งเดียวต่อการเปิดแอป
  static bool _googleReady = false;

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
      // หน้าเลือกบัญชีแบบเนทีฟของ Android (Credential Manager) — ไม่ผ่านเบราว์เซอร์
      // Web client ID อ่านจาก google-services.json ให้อัตโนมัติ
      final google = GoogleSignIn.instance;
      if (!_googleReady) {
        await google.initialize();
        _googleReady = true;
      }
      final account = await google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AuthException(
            'google-no-token', 'เข้าสู่ระบบด้วย Google ไม่สำเร็จ กรุณาลองใหม่');
      }
      final cred = await _auth.signInWithCredential(
          fb.GoogleAuthProvider.credential(idToken: idToken));
      return _toAppUser(cred.user)!;
    } on GoogleSignInException catch (e) {
      debugPrint('Google sign-in error: ${e.code} ${e.description}');
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw AuthException.fromCode('canceled');
      }
      throw AuthException.fromCode('google-sign-in-failed');
    } on fb.FirebaseAuthException catch (e) {
      debugPrint('Google sign-in error: ${e.code} ${e.message}');
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
  Future<void> signOut() async {
    // ออกจาก Google ด้วย ครั้งหน้าจะได้เลือกบัญชีใหม่ได้
    if (_googleReady) {
      try {
        await GoogleSignIn.instance.signOut();
      } on GoogleSignInException {
        // ไม่ได้ล็อกอินด้วย Google — ข้ามได้
      }
    }
    await _auth.signOut();
  }
}