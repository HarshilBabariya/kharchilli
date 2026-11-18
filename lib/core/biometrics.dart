import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

/// Fingerprint or face check by the phone itself; every call answers false when the phone cannot do it.
class Biometrics {
  static final _auth = LocalAuthentication();

  static Future<bool> available() async {
    try {
      return await _auth.isDeviceSupported() && await _auth.canCheckBiometrics;
    } catch (e) {
      debugPrint('Biometrics unavailable: $e');
      return false;
    }
  }

  static Future<bool> confirm(String reason) async {
    try {
      return await _auth.authenticate(localizedReason: reason, options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true));
    } catch (e) {
      debugPrint('Biometric check failed: $e');
      return false;
    }
  }
}
