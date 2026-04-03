import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_text_field.dart';

class EmailAuthScreen extends StatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  String? _emailError;
  String? _passwordError;

  // Toggled manually for UI demo; in TASK-008 this will be driven by
  // whether the entered email already exists in Supabase.
  bool _isSignIn = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  bool _validateEmail(String value) {
    final emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-z]{2,}$');
    if (value.isEmpty) {
      setState(() => _emailError = 'Email is required');
      return false;
    }
    if (!emailRegex.hasMatch(value)) {
      setState(() => _emailError = 'Enter a valid email address');
      return false;
    }
    setState(() => _emailError = null);
    return true;
  }

  bool _validatePassword(String value) {
    if (value.isEmpty) {
      setState(() => _passwordError = 'Password is required');
      return false;
    }
    if (value.length < 8) {
      setState(() => _passwordError = 'Password must be at least 8 characters');
      return false;
    }
    setState(() => _passwordError = null);
    return true;
  }

  void _onSubmit() {
    final emailOk = _validateEmail(_emailController.text.trim());
    final passwordOk = _validatePassword(_passwordController.text);
    if (!emailOk || !passwordOk) return;
    // Auth logic wired in TASK-008
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= AppConstants.mobileBreakpoint) {
            return _DesktopView(child: _buildForm());
          }
          return _MobileView(child: _buildForm());
        },
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Email field
        AppTextField(
          controller: _emailController,
          focusNode: _emailFocus,
          hint: 'you@example.com',
          label: 'Email',
          errorText: _emailError,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _passwordFocus.requestFocus(),
          onChanged: (_) {
            if (_emailError != null) setState(() => _emailError = null);
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        // Password field
        AppTextField(
          controller: _passwordController,
          focusNode: _passwordFocus,
          hint: 'Min. 8 characters',
          label: 'Password',
          errorText: _passwordError,
          obscureText: true,
          showPasswordToggle: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _onSubmit(),
          onChanged: (_) {
            if (_passwordError != null) setState(() => _passwordError = null);
          },
        ),
        const SizedBox(height: AppSpacing.xs),
        // Password hint
        if (!_isSignIn)
          const Padding(
            padding: EdgeInsets.only(left: AppSpacing.xs),
            child: Text(
              'Minimum 8 characters',
              style: TextStyle(
                fontFamily: AppTypography.bodyFont,
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.xxl),
        // Primary action button
        AppButton(
          label: _isSignIn ? 'Sign in' : 'Create account',
          onPressed: _onSubmit,
        ),
        // Forgot password (sign-in state only)
        if (_isSignIn) ...[
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: GestureDetector(
              onTap: () {},
              child: const Text(
                'Forgot password?',
                style: TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xxl),
        // Mode toggle
        Center(
          child: GestureDetector(
            onTap: () => setState(() => _isSignIn = !_isSignIn),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
                children: [
                  TextSpan(
                    text: _isSignIn ? "Don't have an account? " : 'Already have an account? ',
                  ),
                  TextSpan(
                    text: _isSignIn ? 'Create one' : 'Sign in',
                    style: const TextStyle(
                      color: AppColors.golden,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Layout wrappers ─────────────────────────────────────────────────────────

class _MobileView extends StatelessWidget {
  const _MobileView({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        topPadding + AppSpacing.sm,
        AppSpacing.xxl,
        AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          _BackButton(),
          const SizedBox(height: AppSpacing.xxxl),
          // Title
          const Text(
            'Welcome back',
            style: TextStyle(
              fontFamily: AppTypography.displayFont,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Sign in to continue',
            style: TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          child,
        ],
      ),
    );
  }
}

class _DesktopView extends StatelessWidget {
  const _DesktopView({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 380,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.massive),
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BackButton(),
              const SizedBox(height: AppSpacing.xxl),
              const Text(
                'Welcome back',
                style: TextStyle(
                  fontFamily: AppTypography.displayFont,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Sign in to continue',
                style: TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).maybePop(),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_back_ios, size: 16, color: AppColors.textSecondary),
          SizedBox(width: 4),
          Text(
            'Back',
            style: TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
