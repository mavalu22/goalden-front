import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/pressable.dart';

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

bool get _isApplePlatform =>
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.macOS;

// ─── Desktop ─────────────────────────────────────────────────────────────────

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
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.giant,
            vertical: AppSpacing.huge,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left — hero / marketing column
              const Expanded(
                flex: 11,
                child: _HeroColumn(),
              ),
              const SizedBox(width: 50),
              // Right — auth card
              Expanded(
                flex: 10,
                child: _AuthCard(
                  isLoading: isLoading,
                  onGoogle: _signInWithGoogle,
                  onApple: _signInWithApple,
                  ref: ref,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroColumn extends StatelessWidget {
  const _HeroColumn();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo
        const _GoldenLogo(fontSize: 18, letterSpacing: 4),
        const SizedBox(height: AppSpacing.xl),
        // Headline with squiggle on "on purpose."
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontFamily: AppTypography.displayFont,
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: Color(0xFFF2EAD8),
              height: 1.1,
            ),
            children: [
              TextSpan(text: 'One day at a time, '),
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: _SquiggleText(
                  'on purpose.',
                  style: TextStyle(
                    fontFamily: AppTypography.displayFont,
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF2EAD8),
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Body copy
        const Text(
          'A calm place to plan your days, connect them to what matters, '
          'and actually get things done — without the clutter.',
          style: TextStyle(
            fontFamily: AppTypography.bodyFont,
            fontSize: 14,
            color: Color(0xFFCDC3AE),
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        // Context chips
        const Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _ContextChip('For your work'),
            _ContextChip('For your studies'),
            _ContextChip('For your life'),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        // Example day card
        const _ExampleDayCard(),
      ],
    );
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({
    required this.isLoading,
    required this.onGoogle,
    required this.onApple,
    required this.ref,
  });

  final bool isLoading;
  final VoidCallback onGoogle;
  final VoidCallback onApple;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'GET STARTED',
            style: TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Google button
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
            onPressed: isLoading ? null : onGoogle,
            style: SocialAuthButtonStyle.dark,
          ),
          // Apple — only on Apple platforms
          if (_isApplePlatform) ...[
            const SizedBox(height: AppSpacing.sm),
            SocialAuthButton(
              label: 'Continue with Apple',
              icon: const _AppleIcon(),
              onPressed: isLoading ? null : onApple,
              style: SocialAuthButtonStyle.dark,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          // Email — accent (golden) style
          Builder(
            builder: (ctx) => SocialAuthButton(
              label: 'Continue with Email',
              icon: const Icon(
                Icons.email_outlined,
                size: 18,
                color: AppColors.background,
              ),
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
          const SizedBox(height: AppSpacing.xl),
          // Footer link
          Builder(
            builder: (ctx) => GestureDetector(
              onTap: isLoading
                  ? null
                  : () => Navigator.of(ctx).push(
                        MaterialPageRoute(
                          builder: (_) => const EmailAuthScreen(),
                        ),
                      ),
              child: RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  style: TextStyle(
                    fontFamily: AppTypography.bodyFont,
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                  children: [
                    TextSpan(text: 'New around here? '),
                    TextSpan(
                      text: 'Create an account.',
                      style: TextStyle(
                        color: AppColors.golden,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.golden,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContextChip extends StatelessWidget {
  const _ContextChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: AppTypography.bodyFont,
          fontSize: 11,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _ExampleDayCard extends StatelessWidget {
  const _ExampleDayCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'A DAY IN GOALDEN',
            style: TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
              color: AppColors.textMuted,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            'Wednesday, April 22',
            style: TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFFF2EAD8),
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          // Done task — golden tinted
          _ExampleTask(
            label: 'Finish the presentation',
            done: true,
          ),
          SizedBox(height: AppSpacing.xs),
          _ExampleTask(label: '30 min run', opacity: 0.8),
          SizedBox(height: AppSpacing.xs),
          _ExampleTask(label: 'Call mom', opacity: 0.7),
        ],
      ),
    );
  }
}

class _ExampleTask extends StatelessWidget {
  const _ExampleTask({
    required this.label,
    this.done = false,
    this.opacity = 1.0,
  });

  final String label;
  final bool done;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: done
            ? BoxDecoration(
                color: AppColors.golden.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.golden.withValues(alpha: 0.5),
                ),
              )
            : null,
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? AppColors.golden : Colors.transparent,
                border: Border.all(
                  color: done
                      ? AppColors.golden
                      : AppColors.border.withValues(alpha: 0.6),
                  width: 1.5,
                ),
              ),
              child: done
                  ? const Icon(
                      Icons.check,
                      size: 10,
                      color: AppColors.background,
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: const TextStyle(
                fontFamily: AppTypography.bodyFont,
                fontSize: 12,
                color: Color(0xFFF2EAD8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Squiggle underline text ─────────────────────────────────────────────────

class _SquiggleText extends StatelessWidget {
  const _SquiggleText(this.text, {required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _SquigglePainter(color: AppColors.golden),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Text(text, style: style),
      ),
    );
  }
}

class _SquigglePainter extends CustomPainter {
  const _SquigglePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const waveWidth = 8.0;
    const waveHeight = 2.0;
    final y = size.height - 1.5;
    final path = Path()..moveTo(0, y);

    var x = 0.0;
    var up = true;
    while (x < size.width) {
      final nextX = math.min(x + waveWidth, size.width);
      final midX = x + (nextX - x) / 2;
      path.quadraticBezierTo(
        midX,
        up ? y - waveHeight : y + waveHeight,
        nextX,
        y,
      );
      x = nextX;
      up = !up;
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SquigglePainter oldDelegate) =>
      oldDelegate.color != color;
}

// ─── Mobile ───────────────────────────────────────────────────────────────────

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
            'One day at a time, on purpose.',
            style: TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),
          const Spacer(),
          // Google — always first
          SocialAuthButton(
            label: isLoading ? '' : 'Continue with Google',
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
          // Apple — only on Apple platforms
          if (_isApplePlatform) ...[
            const SizedBox(height: AppSpacing.sm),
            SocialAuthButton(
              label: 'Continue with Apple',
              icon: const _AppleIcon(color: Colors.white),
              onPressed: isLoading ? null : _signInWithApple,
              style: SocialAuthButtonStyle.black,
            ),
          ],
          const SizedBox(height: AppSpacing.xxl),
          Center(
            child: Builder(
              builder: (ctx) => Pressable(
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

// ─── Shared widgets ───────────────────────────────────────────────────────────

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

// ─── Social icons ──────────────────────────────────────────────────────────────

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
