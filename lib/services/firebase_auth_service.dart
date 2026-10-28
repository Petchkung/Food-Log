import 'package:firebase_auth/firebase_auth.dart' as fb;

import 'auth_service.dart';

/// ล็อกอินด้วย Firebase Authentication (อีเมล/รหัสผ่าน)
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
  Future<void> signOut() => _auth.signOut();
}