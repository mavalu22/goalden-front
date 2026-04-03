import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

enum AppCardVariant { default_, golden }

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.variant = AppCardVariant.default_,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
  });

  final Widget child;
  final AppCardVariant variant;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = switch (variant) {
      AppCardVariant.default_ => AppColors.border,
      AppCardVariant.golden => AppColors.goldenBorder,
    };

    final backgroundColor = switch (variant) {
      AppCardVariant.default_ => AppColors.surface,
      AppCardVariant.golden => AppColors.goldenDim,
    };

    final card = Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      padding: padding,
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.goldenDim,
          highlightColor: AppColors.goldenDim.withValues(alpha: 0.5),
          child: card,
        ),
      );
    }

    return card;
  }
}
