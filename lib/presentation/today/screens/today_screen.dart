import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppConstants.mobileBreakpoint) {
          return const _DesktopTodayView();
        }
        return const _MobileTodayView();
      },
    );
  }
}

// ─── Mobile ──────────────────────────────────────────────────────────────────

class _MobileTodayView extends StatelessWidget {
  const _MobileTodayView();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayOfWeek = DateFormat('EEEE').format(now).toUpperCase();
    final dateLabel = DateFormat('MMMM d').format(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Day of week
              Text(
                dayOfWeek,
                style: const TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 2),
              // Date
              Text(
                dateLabel,
                style: const TextStyle(
                  fontFamily: AppTypography.displayFont,
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Quick task input
              _QuickTaskInput(),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        // Task list / empty state
        const Expanded(child: _EmptyState()),
      ],
    );
  }
}

// ─── Desktop ─────────────────────────────────────────────────────────────────

class _DesktopTodayView extends StatelessWidget {
  const _DesktopTodayView();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final focusLabel = "TODAY'S FOCUS";
    final dateLabel = DateFormat('EEEE, MMMM d').format(now);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxxl,
        AppSpacing.xxl,
        AppSpacing.xxxl,
        AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "TODAY'S FOCUS" label
          Text(
            focusLabel,
            style: const TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Date heading
          Text(
            dateLabel,
            style: const TextStyle(
              fontFamily: AppTypography.displayFont,
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          // Quote card
          const _QuoteCard(),
          const SizedBox(height: AppSpacing.xxl),
          // Task input
          _QuickTaskInput(hint: 'Pick a task to focus on...'),
          const SizedBox(height: AppSpacing.xxxl),
          // Empty state
          const _EmptyState(),
        ],
      ),
    );
  }
}

// ─── Shared widgets ──────────────────────────────────────────────────────────

class _QuickTaskInput extends StatelessWidget {
  const _QuickTaskInput({this.hint = 'New task...'});

  final String hint;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              style: const TextStyle(
                fontFamily: AppTypography.bodyFont,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // Golden "+" button
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.golden,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.add, color: AppColors.background, size: 22),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: AppSpacing.xxxl),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: AppColors.textMuted,
              size: 28,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'No tasks for today.',
            style: TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Enjoy your day!',
            style: TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text(
                  '"The secret of your future is hidden in your daily routine."',
                  style: TextStyle(
                    fontFamily: AppTypography.displayFont,
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                '❝',
                style: TextStyle(
                  fontSize: 32,
                  color: AppColors.golden.withOpacity(0.3),
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Mike Murdock',
            style: TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
