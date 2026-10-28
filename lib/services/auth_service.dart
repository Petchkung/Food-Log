/// ผู้ใช้ที่ล็อกอินอยู่ (แยกจาก Firebase User เพื่อให้ทดสอบง่าย)
class AppUser {
  const AppUser({required this.uid, required this.email});
  final String uid;
  final String email;
}

/// ข้อผิดพลาดตอนล็อกอิน พร้อมข้อความภาษาไทยไว้แสดงผู้ใช้
class AuthException implements Exception {
  const AuthException(this.code, this.message);
  final String code;
  final String message;

  /// แปลงรหัส error ของ Firebase เป็นข้อความไทย
  /// (ไม่บอกว่าอีเมลนี้มีบัญชีหรือไม่ — กันคนสุ่มเดาอีเมล)
  factory AuthException.fromCode(String code) {
    switch (code) {
      case 'invalid-email':
        return AuthException(code, 'รูปแบบอีเมลไม่ถูกต้อง');
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return AuthException(code, 'อีเมลหรือรหัสผ่านไม่ถูกต้อง');
      case 'email-already-in-use':
        return AuthException(code, 'ไม่สามารถสมัครด้วยอีเมลนี้ได้');
      case 'weak-password':
        return AuthException(code, 'รหัสผ่านไม่ปลอดภัยพอ');
      case 'too-many-requests':
        return AuthException(code, 'พยายามหลายครั้งเกินไป กรุณารอสักครู่');
      case 'network-request-failed':
        return AuthException(code, 'เชื่อมต่ออินเทอร์เน็ตไม่ได้');
      default:
        return AuthException(code, 'เกิดข้อผิดพลาด กรุณาลองใหม่');
    }
  }

  @override
  String toString() => 'AuthException($code)';
}

/// สิ่งที่ระบบ Login ต้องทำได้
abstract class AuthService {
  Stream<AppUser?> authStateChanges();
  AppUser? get currentUser;
  Future<AppUser> signIn({required String email, required String password});
  Future<AppUser> signUp({required String email, required String password});
  Future<void> signOut();
}