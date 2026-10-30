import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

/// debug token ของทีม — ส่งตอนรัน ห้าม commit ลงไฟล์:
/// flutter run --dart-define=APP_CHECK_DEBUG_TOKEN=xxxx
const appCheckDebugToken = String.fromEnvironment('APP_CHECK_DEBUG_TOKEN');

/// เปิด App Check: ตอนพัฒนาใช้ debug provider, ตอน release ใช้ Play Integrity / DeviceCheck
Future<void> activateAppCheck() => FirebaseAppCheck.instance.activate(
      providerAndroid: kReleaseMode
          ? const AndroidPlayIntegrityProvider()
          : AndroidDebugProvider(
              debugToken: appCheckDebugToken.isEmpty ? null : appCheckDebugToken),
      providerApple:
          kReleaseMode ? const AppleDeviceCheckProvider() : const AppleDebugProvider(),
    );