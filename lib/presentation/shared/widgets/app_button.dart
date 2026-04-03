import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

enum AppButtonVariant { primary, secondary, ghost }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final Widget? icon;
  final bool isLoading;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _foregroundColor,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                IconTheme(
                  data: IconThemeData(color: _foregroundColor, size: 20),
                  child: icon!,
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _foregroundColor,
                ),
              ),
            ],
          );

    final button = SizedBox(
      height: 52,
      child: switch (variant) {
        AppButtonVariant.primary => ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.golden,
              foregroundColor: AppColors.background,
              disabledBackgroundColor: AppColors.golden.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            ),
            child: child,
          ),
        AppButtonVariant.secondary => OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.border, width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            ),
            child: child,
          ),
        AppButtonVariant.ghost => TextButton(
            onPressed: isLoading ? null : onPressed,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            ),
            child: child,
          ),
      },
    );

    if (expanded) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }

  Color get _foregroundColor => switch (variant) {
        AppButtonVariant.primary => AppColors.background,
        AppButtonVariant.secondary => AppColors.textPrimary,
        AppButtonVariant.ghost => AppColors.textSecondary,
      };
}
