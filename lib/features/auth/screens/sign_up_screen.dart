import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/state/app_state.dart';
import '../../../core/services/auth_service.dart';
import '../../legal/screens/privacy_policy_screen.dart';
import '../widgets/google_sign_in_button.dart';
import '../../legal/screens/terms_of_use_screen.dart';

class SignUpScreen extends StatefulWidget {
  final AppState appState;
  final VoidCallback? onBackToSignIn;

  const SignUpScreen({
    super.key,
    required this.appState,
    this.onBackToSignIn,
  });

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _termsAccepted = false;
  String _bloodType = 'Unknown';
  String? _errorText;

  static const _bloodTypes = ['Unknown', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    setState(() => _errorText = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_termsAccepted) {
      setState(() => _errorText =
          'Please confirm you are 18 or older and accept the Terms and Privacy Policy.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await widget.appState.register(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        bloodType: _bloodType,
      );
      // MaterialApp home switches to the shell automatically when signed in.
      // Do not pop — that can remove the new home route.
      if (widget.appState.welcomeNoteSent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cura sent a welcome note to your email.')),
        );
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _errorText = e.message);
    } catch (_) {
      if (mounted) setState(() => _errorText = 'Could not create account. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () {
            if (widget.onBackToSignIn != null) {
              widget.onBackToSignIn!();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          'Create Account',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Set up your health profile',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Continue with Google, or use your email. Your account opens right away.',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 28),
                GoogleSignInButton(
                  appState: widget.appState,
                  enabled: !_isLoading,
                  beforeStart: () => _termsAccepted
                      ? null
                      : 'Please confirm you are 18 or older and accept the Terms and Privacy Policy.',
                  onError: (message) {
                    if (mounted) setState(() => _errorText = message);
                  },
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Expanded(child: Divider(color: Color(0xFFD9D4E0))),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'or use email',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Color(0xFFD9D4E0))),
                  ],
                ),
                const SizedBox(height: 16),
                _label('Full name'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      (v == null || v.trim().length < 2) ? 'Enter your full name' : null,
                  decoration: _decoration('e.g. Alex Rivera', Icons.person_outline_rounded),
                ),
                const SizedBox(height: 16),
                _label('Email'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: (v) {
                    final email = v?.trim() ?? '';
                    if (email.isEmpty) return 'Email is required';
                    if (!email.contains('@') || !email.contains('.')) return 'Enter a valid email';
                    return null;
                  },
                  decoration: _decoration('you@gmail.com', Icons.email_outlined),
                ),
                const SizedBox(height: 16),
                _label('Blood type (optional)'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _bloodType,
                  items: _bloodTypes
                      .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                      .toList(),
                  onChanged: (v) => setState(() => _bloodType = v ?? 'Unknown'),
                  decoration: _decoration('Blood type', Icons.bloodtype_outlined),
                ),
                const SizedBox(height: 16),
                _label('Password'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: (v) {
                    if ((v ?? '').length < 6) return 'At least 6 characters';
                    return null;
                  },
                  decoration: _decoration(
                    'Create a password',
                    Icons.lock_outline_rounded,
                    suffix: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _label('Confirm password'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleSignUp(),
                  validator: (v) {
                    if (v != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                  decoration: _decoration(
                    'Re-enter password',
                    Icons.lock_outline_rounded,
                    suffix: IconButton(
                      icon: Icon(
                        _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _termsAccepted,
                      onChanged: (v) => setState(() => _termsAccepted = v ?? false),
                      visualDensity: VisualDensity.compact,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'I am 18 or older and I accept the ',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                            _legalLink('Terms of Use', const TermsOfUseScreen()),
                            Text(
                              ' and ',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                            _legalLink('Privacy Policy', const PrivacyPolicyScreen()),
                            Text(
                              '.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorText!,
                    style: TextStyle(
                      color: AppColors.accentCoral,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    ),
                    onPressed: _isLoading ? null : _handleSignUp,
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : Text(
                            'Create Account',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () {
                      if (widget.onBackToSignIn != null) {
                        widget.onBackToSignIn!();
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    child: Text(
                      'Already have an account? Sign in',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryContainer,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _legalLink(String label, Widget screen) => GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screen),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryContainer,
            decoration: TextDecoration.underline,
            decorationColor: AppColors.primaryContainer,
          ),
        ),
      );

  Widget _label(String text) => Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      );

  InputDecoration _decoration(String hint, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textSecondary),
      prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.surfaceCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primaryContainer, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.accentCoral),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.accentCoral, width: 1.5),
      ),
    );
  }
}
