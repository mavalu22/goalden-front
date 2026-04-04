import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

enum SocialAuthButtonStyle { dark, light, black, primary }

class SocialAuthButton extends StatefulWidget {
  const SocialAuthButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.style = SocialAuthButtonStyle.dark,
  });

  final String label;
  final Widget icon;
  final VoidCallback? onPressed;
  final SocialAuthButtonStyle style;

  @override
  State<SocialAuthButton> createState() => _SocialAuthButtonState();
}

class _SocialAuthButtonState extends State<SocialAuthButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = switch (widget.style) {
      SocialAuthButtonStyle.dark => AppColors.surfaceElevated,
      SocialAuthButtonStyle.light => const Color(0xFFF5F3EE),
      SocialAuthButtonStyle.black => const Color(0xFF000000),
      SocialAuthButtonStyle.primary => AppColors.golden,
    };

    final foregroundColor = switch (widget.style) {
      SocialAuthButtonStyle.dark => AppColors.textPrimary,
      SocialAuthButtonStyle.light => const Color(0xFF1A1A1A),
      SocialAuthButtonStyle.black => Colors.white,
      SocialAuthButtonStyle.primary => AppColors.background,
    };

    final borderColor = switch (widget.style) {
      SocialAuthButtonStyle.dark => AppColors.border,
      SocialAuthButtonStyle.light => const Color(0xFFD8D5CE),
      SocialAuthButtonStyle.black => Colors.transparent,
      SocialAuthButtonStyle.primary => Colors.transparent,
    };

    final hoverColor = switch (widget.style) {
      SocialAuthButtonStyle.dark => Colors.white.withValues(alpha: 0.05),
      SocialAuthButtonStyle.light => Colors.black.withValues(alpha: 0.05),
      SocialAuthButtonStyle.black => Colors.white.withValues(alpha: 0.08),
      SocialAuthButtonStyle.primary => Colors.white.withValues(alpha: 0.1),
    };

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: widget.onPressed,
            mouseCursor: widget.onPressed != null
                ? SystemMouseCursors.click
                : SystemMouseCursors.forbidden,
            hoverColor: hoverColor,
            borderRadius: BorderRadius.circular(12),
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  widget.icon,
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontFamily: AppTypography.bodyFont,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: foregroundColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
