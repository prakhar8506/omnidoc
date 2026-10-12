import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_colors.dart';

/// Opens the Google account picker and signs that account in on this device.
class GoogleSignInButton extends StatefulWidget {
  final AppState appState;
  final bool enabled;

  /// Return a message to block the tap (for example, terms not accepted).
  final String? Function()? beforeStart;
  final ValueChanged<String>? onError;

  const GoogleSignInButton({
    super.key,
    required this.appState,
    this.enabled = true,
    this.beforeStart,
    this.onError,
  });

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  bool _busy = false;

  Future<void> _start() async {
    final blocked = widget.beforeStart?.call();
    if (blocked != null) {
      widget.onError?.call(blocked);
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.appState.signInWithGoogle();
    } on AuthException catch (e) {
      widget.onError?.call(e.message);
    } catch (_) {
      widget.onError?.call('Could not sign in with Google. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canTap = widget.enabled && !_busy;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          side: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.25)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        ),
        onPressed: canTap ? _start : null,
        child: _busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _GoogleMark(),
                  SizedBox(width: 10),
                  Text(
                    'Continue with Google',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return const Text.rich(
      TextSpan(
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, height: 1),
        children: [
          TextSpan(text: 'G', style: TextStyle(color: Color(0xFF4285F4))),
          TextSpan(text: 'o', style: TextStyle(color: Color(0xFFEA4335))),
          TextSpan(text: 'o', style: TextStyle(color: Color(0xFFFBBC05))),
          TextSpan(text: 'g', style: TextStyle(color: Color(0xFF4285F4))),
          TextSpan(text: 'l', style: TextStyle(color: Color(0xFF34A853))),
          TextSpan(text: 'e', style: TextStyle(color: Color(0xFFEA4335))),
        ],
      ),
    );
  }
}
