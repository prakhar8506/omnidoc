import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../env/app_env.dart';
import 'auth_service.dart';

/// Google account chosen in the system account picker.
class GoogleAccount {
  final String id;
  final String email;
  final String? displayName;

  const GoogleAccount({
    required this.id,
    required this.email,
    this.displayName,
  });
}

/// Signs in with the Google Sign-In SDK. No Supabase call is made.
class GoogleAuth {
  static bool _ready = false;

  static Future<void> _ensureReady() async {
    if (_ready) return;
    final serverClientId = AppEnv.googleWebClientId.trim();
    if (serverClientId.isEmpty) {
      throw AuthException(
        'Google sign-in needs a Web client ID from Google Cloud before it can open.',
      );
    }
    final iosClientId = AppEnv.googleIosClientId.trim();
    final useIosClient = !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.iOS &&
        iosClientId.isNotEmpty;
    await GoogleSignIn.instance.initialize(
      clientId: useIosClient ? iosClientId : null,
      serverClientId: serverClientId,
    );
    _ready = true;
  }

  static Future<GoogleAccount> pickAccount() async {
    await _ensureReady();
    try {
      final account = await GoogleSignIn.instance.authenticate();
      final email = account.email.trim();
      if (email.isEmpty) {
        throw AuthException('Google did not share an email address.');
      }
      return GoogleAccount(
        id: account.id.trim(),
        email: email,
        displayName: account.displayName,
      );
    } on AuthException {
      rethrow;
    } on GoogleSignInException catch (e) {
      final detail = (e.description ?? '').toLowerCase();
      debugPrint('[GoogleAuth] ${e.code} ${e.description}');
      final certificateMismatch = detail.contains('reauth') ||
          detail.contains('not registered') ||
          detail.contains('developer_error') ||
          detail.contains('sha');
      switch (e.code) {
        case GoogleSignInExceptionCode.canceled:
          if (certificateMismatch) {
            throw AuthException(
              'Google could not confirm this install. Wait a few minutes and try again.',
            );
          }
          throw AuthException('Google sign-in was cancelled.');
        case GoogleSignInExceptionCode.clientConfigurationError:
        case GoogleSignInExceptionCode.providerConfigurationError:
          throw AuthException(
            'Google sign-in needs a Web client ID from Google Cloud before it can open.',
          );
        default:
          if (certificateMismatch) {
            throw AuthException(
              'Google could not confirm this install. Wait a few minutes and try again.',
            );
          }
          throw AuthException('Could not sign in with Google. Please try again.');
      }
    }
  }

  static Future<void> signOut() async {
    if (!_ready) return;
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }
}
