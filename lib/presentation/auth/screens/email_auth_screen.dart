import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/models/auth_user.dart';
import '../../../providers/auth_provider.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_text_field.dart';

class EmailAuthScreen extends ConsumerStatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  ConsumerState<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends ConsumerState<EmailAuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  String? _emailError;
  String? _passwordError;
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

  Future<void> _onSubmit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final emailOk = _validateEmail(email);
    final passwordOk = _validatePassword(password);
    if (!emailOk || !passwordOk) return;

    if (_isSignIn) {
      await ref.read(authActionsProvider.notifier).signInWithEmail(
            email: email,
            password: password,
          );
    } else {
      await ref.read(authActionsProvider.notifier).signUpWithEmail(
            email: email,
            password: password,
          );

      // Check synchronously via the Supabase client — the Riverpod stream
      // may not have propagated yet, so reading it would give a stale value.
      if (!mounted) return;
      final hasError = ref.read(authActionsProvider).hasError;
      final isSignedIn =
          Supabase.instance.client.auth.currentUser != null;
      if (!hasError && !isSignedIn) {
        // Email confirmation is required — tell the user to check their inbox.
        _showEmailConfirmationDialog(email);
      }
    }
  }

  void _showEmailConfirmationDialog(String email) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Text(
          'Check your email',
          style: TextStyle(
            fontFamily: AppTypography.displayFont,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'We sent a confirmation link to $email.\nOpen it to activate your account.',
          style: const TextStyle(
            fontFamily: AppTypography.bodyFont,
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Got it',
              style: TextStyle(
                fontFamily: AppTypography.bodyFont,
                color: AppColors.golden,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onForgotPassword() async {
    final email = _emailController.text.trim();
    if (!_validateEmail(email)) return;

    await ref
        .read(authActionsProvider.notifier)
        .sendPasswordResetEmail(email);

    if (!mounted) return;
    final hasError = ref.read(authActionsProvider).hasError;
    if (!hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent. Check your inbox.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _friendlyError(Object error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid_credentials')) {
      return 'Wrong email or password.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Please confirm your email before signing in.';
    }
    if (msg.contains('user already registered')) {
      return 'An account with this email already exists.';
    }
    if (msg.contains('network')) return 'Check your internet connection.';
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    // Navigate away as soon as the user becomes authenticated.
    ref.listen<AsyncValue<AppUser?>>(authUserProvider, (_, next) {
      next.whenOrNull(
        data: (user) {
          if (user != null && mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
      );
    });

    ref.listen<AsyncValue<void>>(authActionsProvider, (_, next) {
      next.whenOrNull(
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_friendlyError(error)),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      );
    });

    final isLoading = ref.watch(authActionsProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= AppConstants.mobileBreakpoint) {
            return _DesktopView(child: _buildForm(isLoading));
          }
          return _MobileView(child: _buildForm(isLoading));
        },
      ),
    );
  }

  Widget _buildForm(bool isLoading) {
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
          label: isLoading ? '' : (_isSignIn ? 'Sign in' : 'Create account'),
          onPressed: isLoading ? null : _onSubmit,
          isLoading: isLoading,
        ),
        // Forgot password (sign-in state only)
        if (_isSignIn) ...[
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: GestureDetector(
              onTap: isLoading ? null : _onForgotPassword,
              child: Text(
                'Forgot password?',
                style: TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 13,
                  color: isLoading
                      ? AppColors.textMuted
                      : AppColors.textSecondary,
                  decoration: TextDecoration.underline,
                  decorationColor: isLoading
                      ? AppColors.textMuted
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xxl),
        // Mode toggle
        Center(
          child: GestureDetector(
            onTap: isLoading ? null : () => setState(() => _isSignIn = !_isSignIn),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
                children: [
                  TextSpan(
                    text: _isSignIn
                        ? "Don't have an account? "
                        : 'Already have an account? ',
                  ),
                  TextSpan(
                    text: _isSignIn ? 'Create one' : 'Sign in',
                    style: TextStyle(
                      color: isLoading ? AppColors.textMuted : AppColors.golden,
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
          _BackButton(),
          const SizedBox(height: AppSpacing.xxxl),
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
                color: Colors.black.withValues(alpha: 0.4),
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
