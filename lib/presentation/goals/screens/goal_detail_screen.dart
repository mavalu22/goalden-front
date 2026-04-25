import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/models/goal.dart';

class GoalDetailScreen extends StatelessWidget {
  const GoalDetailScreen({super.key, required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back,
              color: AppColors.textSecondary, size: 20),
        ),
      ),
      body: Center(
        child: Text(
          goal.title,
          style: const TextStyle(
            fontFamily: AppTypography.bodyFont,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
