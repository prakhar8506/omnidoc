import 'package:flutter/material.dart';
import '../../../core/env/app_env.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/google_sign_in_button.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/state/app_state.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/branding/app_brand.dart';
import '../../legal/screens/privacy_policy_screen.dart';
import '../../legal/screens/terms_of_use_screen.dart';
import 'sign_up_screen.dart';

class SignInScreen extends StatefulWidget {
  final AppState appState;

  const SignInScreen({
    super.key,
    required this.appState,
  });

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isDemoLoading = false;
  bool _obscurePassword = true;
  bool _termsAccepted = false;
  bool _showSignUp = false;
  String? _errorText;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    setState(() => _errorText = null);
    if (!_termsAccepted) {
      setState(() => _errorText = 'Please confirm you are 18 or older and accept the Terms and Privacy Policy.');
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      await widget.appState.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );
    } on AuthException catch (e) {
      if (mounted) setState(() => _errorText = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _errorText = 'Unable to sign in. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDemoSignIn() async {
    if (!_termsAccepted) {
      setState(() => _errorText = 'Please confirm you are 18 or older and accept the Terms and Privacy Policy.');
      return;
    }
    setState(() {
      _errorText = null;
      _isDemoLoading = true;
    });
    try {
      await widget.appState.signInDemoAccount();
    } catch (_) {
      if (mounted) {
        setState(() => _errorText = 'Unable to launch demo. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isDemoLoading = false);
    }
  }

  void _openSignUp() {
    setState(() => _showSignUp = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_showSignUp) {
      return SignUpScreen(
        appState: widget.appState,
        onBackToSignIn: () => setState(() => _showSignUp = false),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFAF6FC),
              Color(0xFFFDE8EF),
              Color(0xFFEDEAFE),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 36),
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryContainer.withValues(alpha: 0.35),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.spa_rounded, color: Colors.white, size: 30),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Welcome to\n${AppBrand.name}',
                          style: AppTypography.editorialLg,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppEnv.enableDemo
                              ? '${AppBrand.tagline} — personalized wellness, triage, and AI report analysis.'
                              : 'Sign in with your account. ${AppBrand.tagline} for wellness, triage, and AI report analysis.',
                          style: AppTypography.bodyMd,
                        ),
                        const SizedBox(height: 28),
                        GoogleSignInButton(
                          appState: widget.appState,
                          enabled: !_isLoading && !_isDemoLoading,
                          beforeStart: () => _termsAccepted
                              ? null
                              : 'Please confirm you are 18 or older and accept the Terms and Privacy Policy.',
                          onError: (message) {
                            if (mounted) setState(() => _errorText = message);
                          },
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: _termsAccepted,
                              onChanged: (value) => setState(() => _termsAccepted = value ?? false),
                              visualDensity: VisualDensity.compact,
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text('I am 18 or older and I accept the ', style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.textSecondary)),
                                    GestureDetector(
                                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsOfUseScreen())),
                                      child: Text('Terms of Use', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryContainer)),
                                    ),
                                    Text(' and ', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                    GestureDetector(
                                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
                                      child: Text('Privacy Policy', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryContainer)),
                                    ),
                                    Text('.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(child: Divider(color: AppColors.textTertiary.withValues(alpha: 0.3))),
                            const Padding(
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
                            Expanded(child: Divider(color: AppColors.textTertiary.withValues(alpha: 0.3))),
                          ],
                        ),
                        const SizedBox(height: 20),

                        if (AppEnv.enableDemo) ...[
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.textPrimary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                shadowColor: AppColors.textPrimary.withValues(alpha: 0.3),
                              ),
                              icon: _isDemoLoading
                                  ? const SizedBox.shrink()
                                  : const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFC94A), size: 18),
                              label: _isDemoLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : Text(
                                      'Try demo mode',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                    ),
                              onPressed: _isDemoLoading ? null : _handleDemoSignIn,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],

                        Text(
                          'Email',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          style: TextStyle(
                            fontSize: 15,
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            if (email.isEmpty) return 'Email is required';
                            if (!email.contains('@') || !email.contains('.')) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                          decoration: _fieldDecoration(
                            hint: 'your.email@icloud.com',
                            prefix: Icons.email_outlined,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Password',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) => _handleSignIn(),
                          style: TextStyle(
                            fontSize: 15,
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                          validator: (value) {
                            if ((value ?? '').isEmpty) return 'Password is required';
                            return null;
                          },
                          decoration: _fieldDecoration(
                            hint: 'Enter your password',
                            prefix: Icons.lock_outline_rounded,
                            suffix: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
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
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryContainer,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              disabledBackgroundColor:
                                  AppColors.primaryContainer.withValues(alpha: 0.5),
                            ),
                            onPressed: _isLoading ? null : _handleSignIn,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.3)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            onPressed: _isLoading ? null : _openSignUp,
                            child: Text(
                              'Create New Account',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.8),
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.shield_outlined,
                                  size: 18, color: AppColors.primaryContainer),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Accounts are secure & private on this device.\nClinical guidance is non-emergency.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData prefix,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textTertiary),
      prefixIcon: Icon(prefix, color: AppColors.textSecondary, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.9)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.9)),
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
