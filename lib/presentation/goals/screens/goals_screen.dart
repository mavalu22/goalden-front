import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Goals screen — navigation destination for the Goals tab.
/// Full grid layout is implemented in TASK-111.
class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text(
          'Goals',
          style: TextStyle(
            fontFamily: AppTypography.bodyFont,
            fontSize: 18,
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
