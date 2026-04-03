import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/auth_provider.dart';
import '../widgets/social_auth_button.dart';
import 'email_auth_screen.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen for auth errors and surface them as snackbars
    ref.listen<AsyncValue<void>>(authActionsProvider, (_, next) {
      next.whenOrNull(
        error: (error, _) {
          final message = _friendlyError(error);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
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
            return _DesktopLoginView(isLoading: isLoading, ref: ref);
          }
          return _MobileLoginView(isLoading: isLoading, ref: ref);
        },
      ),
    );
  }

  String _friendlyError(Object error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('cancelled') || msg.contains('canceled')) {
      return 'Sign-in was cancelled.';
    }
    if (msg.contains('network')) return 'Check your internet connection.';
    return 'Sign-in failed. Please try again.';
  }
}

// ─── Desktop ────────────────────────────────────────────────────────────────

class _DesktopLoginView extends StatelessWidget {
  const _DesktopLoginView({required this.isLoading, required this.ref});

  final bool isLoading;
  final WidgetRef ref;

  void _signInWithGoogle() =>
      ref.read(authActionsProvider.notifier).signInWithGoogle();

  void _signInWithApple() =>
      ref.read(authActionsProvider.notifier).signInWithApple();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const _AmbientBackground(),
        Center(
          child: SizedBox(
            width: 380,
            child: Container(
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
                children: [
                  const _GoldenLogo(fontSize: 28, letterSpacing: 4),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Your moves, simplified.',
                    style: TextStyle(
                      fontFamily: AppTypography.bodyFont,
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  // Apple
                  SocialAuthButton(
                    label: 'Continue with Apple',
                    icon: const _AppleIcon(),
                    onPressed: isLoading ? null : _signInWithApple,
                    style: SocialAuthButtonStyle.dark,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Google
                  SocialAuthButton(
                    label: isLoading ? '' : 'Continue with Google',
                    icon: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textPrimary,
                            ),
                          )
                        : const _GoogleIcon(),
                    onPressed: isLoading ? null : _signInWithGoogle,
                    style: SocialAuthButtonStyle.dark,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const _OrDivider(),
                  const SizedBox(height: AppSpacing.lg),
                  // Email
                  Builder(
                    builder: (ctx) => SocialAuthButton(
                      label: 'Sign in with Email',
                      icon: const Icon(Icons.email_outlined, size: 18),
                      onPressed: isLoading
                          ? null
                          : () => Navigator.of(ctx).push(
                                MaterialPageRoute(
                                  builder: (_) => const EmailAuthScreen(),
                                ),
                              ),
                      style: SocialAuthButtonStyle.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  GestureDetector(
                    onTap: () {},
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontFamily: AppTypography.bodyFont,
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                        children: [
                          TextSpan(text: 'New to this concept? '),
                          TextSpan(
                            text: 'Request access.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
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

// ─── Mobile ─────────────────────────────────────────────────────────────────

class _MobileLoginView extends StatelessWidget {
  const _MobileLoginView({required this.isLoading, required this.ref});

  final bool isLoading;
  final WidgetRef ref;

  void _signInWithGoogle() =>
      ref.read(authActionsProvider.notifier).signInWithGoogle();

  void _signInWithApple() =>
      ref.read(authActionsProvider.notifier).signInWithApple();

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        topPadding + AppSpacing.massive,
        AppSpacing.xxl,
        bottomPadding + AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _GoldenLogo(fontSize: 40, letterSpacing: 10),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Your week, simplified.',
            style: TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),
          const Spacer(),
          // Google
          SocialAuthButton(
            label: isLoading ? '' : 'Sign in with Google',
            icon: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF1A1A1A),
                    ),
                  )
                : const _GoogleIcon(),
            onPressed: isLoading ? null : _signInWithGoogle,
            style: SocialAuthButtonStyle.light,
          ),
          const SizedBox(height: AppSpacing.sm),
          // Apple
          SocialAuthButton(
            label: 'Sign in with Apple',
            icon: const _AppleIcon(color: Colors.white),
            onPressed: isLoading ? null : _signInWithApple,
            style: SocialAuthButtonStyle.black,
          ),
          const SizedBox(height: AppSpacing.xxl),
          Center(
            child: Builder(
              builder: (ctx) => GestureDetector(
                onTap: isLoading
                    ? null
                    : () => Navigator.of(ctx).push(
                          MaterialPageRoute(
                            builder: (_) => const EmailAuthScreen(),
                          ),
                        ),
                child: Text(
                  'Sign in with email',
                  style: TextStyle(
                    fontFamily: AppTypography.bodyFont,
                    fontSize: 14,
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
          ),
        ],
      ),
    );
  }
}

// ─── Shared widgets ──────────────────────────────────────────────────────────

class _GoldenLogo extends StatelessWidget {
  const _GoldenLogo({required this.fontSize, required this.letterSpacing});

  final double fontSize;
  final double letterSpacing;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [
          Color(0xFFB8902A),
          Color(0xFFD4AF37),
          Color(0xFFF0CB60),
          Color(0xFFD4AF37),
        ],
        stops: [0.0, 0.35, 0.65, 1.0],
      ).createShader(bounds),
      child: Text(
        'GOALDEN',
        style: TextStyle(
          fontFamily: AppTypography.displayFont,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: letterSpacing,
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: AppColors.border, height: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'or',
            style: TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ),
        Expanded(child: Divider(color: AppColors.border, height: 1)),
      ],
    );
  }
}

class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _AmbientPainter());
  }
}

class _AmbientPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.7, 0.2),
        radius: 0.8,
        colors: [
          const Color(0xFFD4AF37).withValues(alpha: 0.08),
          const Color(0xFF141414).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Social icons ─────────────────────────────────────────────────────────────

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final bgPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, radius, bgPaint);

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'G',
        style: TextStyle(
          fontFamily: 'sans-serif',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF4285F4),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AppleIcon extends StatelessWidget {
  const _AppleIcon({this.color = AppColors.textPrimary});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.apple, size: 20, color: color);
  }
}
