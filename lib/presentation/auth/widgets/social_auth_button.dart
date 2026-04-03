import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

enum SocialAuthButtonStyle { dark, light, black, primary }

class SocialAuthButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final backgroundColor = switch (style) {
      SocialAuthButtonStyle.dark => AppColors.surfaceElevated,
      SocialAuthButtonStyle.light => const Color(0xFFF5F3EE),
      SocialAuthButtonStyle.black => const Color(0xFF000000),
      SocialAuthButtonStyle.primary => AppColors.golden,
    };

    final foregroundColor = switch (style) {
      SocialAuthButtonStyle.dark => AppColors.textPrimary,
      SocialAuthButtonStyle.light => const Color(0xFF1A1A1A),
      SocialAuthButtonStyle.black => Colors.white,
      SocialAuthButtonStyle.primary => AppColors.background,
    };

    final borderColor = switch (style) {
      SocialAuthButtonStyle.dark => AppColors.border,
      SocialAuthButtonStyle.light => const Color(0xFFD8D5CE),
      SocialAuthButtonStyle.black => Colors.transparent,
      SocialAuthButtonStyle.primary => Colors.transparent,
    };

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                const SizedBox(width: AppSpacing.sm),
                Text(
                  label,
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
    );
  }
}
