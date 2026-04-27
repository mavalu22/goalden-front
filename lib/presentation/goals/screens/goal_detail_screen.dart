import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/goal_colors.dart';
import '../providers/goal_provider.dart';
import '../widgets/goal_form_sheet.dart';
import '../widgets/milestones_panel.dart';
import '../widgets/tasks_panel.dart';

class GoalDetailScreen extends ConsumerWidget {
  const GoalDetailScreen({super.key, required this.goal});

  /// Initial goal passed for the first render. The screen watches
  /// [goalByIdProvider] to stay in sync with subsequent edits.
  final Goal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveGoalAsync = ref.watch(goalByIdProvider(goal.id));
    final liveGoal = liveGoalAsync.valueOrNull ?? goal;

    // Pop back if the goal has been deleted.
    ref.listen(goalByIdProvider(goal.id), (_, next) {
      if (next.valueOrNull == null && next is AsyncData<Goal?>) {
        if (context.mounted) Navigator.of(context).pop();
      }
    });

    final gc = GoalColors.fromId(liveGoal.color);
    final stats = ref.watch(goalDetailStatsProvider(goal.id)).valueOrNull;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop =
            constraints.maxWidth >= AppConstants.mobileBreakpoint;
        final horizontalPadding =
            isDesktop ? AppSpacing.xxxl : AppSpacing.lg;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              // ── Gradient wash ───────────────────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 220,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        gc.soft,
                        gc.soft.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Main content ────────────────────────────────────
              CustomScrollView(
                slivers: [
                  // Back arrow + breadcrumb
                  SliverToBoxAdapter(
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          AppSpacing.md,
                          horizontalPadding,
                          0,
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: const MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Icon(
                                  Icons.arrow_back,
                                  color: AppColors.textSecondary,
                                  size: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            const Text(
                              'Goals',
                              style: TextStyle(
                                fontFamily: AppTypography.bodyFont,
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm),
                              child: Text(
                                '›',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                liveGoal.title,
                                style: TextStyle(
                                  fontFamily: AppTypography.bodyFont,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: gc.base,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.xl)),

                  // Hero card (contains stats)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding),
                      child: _HeroCard(
                        goal: liveGoal,
                        gc: gc,
                        stats: stats,
                        onEdit: () async {
                          await showGoalEditForm(context, goal: liveGoal);
                        },
                        onArchive: () {
                          final notifier =
                              ref.read(goalListProvider.notifier);
                          if (liveGoal.status == GoalStatus.archived) {
                            notifier.unarchiveGoal(liveGoal.id);
                          } else {
                            notifier.archiveGoal(liveGoal.id);
                          }
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.xl)),

                  // Milestones + Tasks panels
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding),
                      child: isDesktop
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: MilestonesPanel(
                                    goalId: liveGoal.id,
                                    gc: gc,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: TasksPanel(
                                    goalId: liveGoal.id,
                                    goalTitle: liveGoal.title,
                                    gc: gc,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                MilestonesPanel(
                                  goalId: liveGoal.id,
                                  gc: gc,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                TasksPanel(
                                  goalId: liveGoal.id,
                                  goalTitle: liveGoal.title,
                                  gc: gc,
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.huge)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Hero card ─────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.goal,
    required this.gc,
    required this.stats,
    required this.onEdit,
    required this.onArchive,
  });

  final Goal goal;
  final GoalColor gc;
  final ({int open, int total, int thisWeek})? stats;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final isArchived = goal.status == GoalStatus.archived;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: gc.dim,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: gc.base, width: 5),
          top: BorderSide(color: gc.base),
          right: BorderSide(color: gc.base),
          bottom: BorderSide(color: gc.base),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title row ───────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.star_rounded, color: gc.base, size: 24),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  goal.title,
                  style: const TextStyle(
                    fontFamily: AppTypography.displayFont,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _StatusChip(isArchived: isArchived, gc: gc),
              const SizedBox(width: AppSpacing.sm),
              _ActionButton(
                label: 'Edit',
                icon: Icons.edit_outlined,
                onTap: onEdit,
              ),
              const SizedBox(width: AppSpacing.xs),
              _ActionButton(
                label: isArchived ? 'Unarchive' : 'Archive',
                icon: isArchived
                    ? Icons.unarchive_outlined
                    : Icons.archive_outlined,
                onTap: onArchive,
              ),
            ],
          ),

          // ── Description ─────────────────────────────────────────
          if (goal.description != null && goal.description!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Text(
                goal.description!,
                style: const TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ],

          // ── Stats ───────────────────────────────────────────────
          if (stats != null) ...[
            const SizedBox(height: AppSpacing.xl),
            _HeroStats(goal: goal, gc: gc, stats: stats!),
          ],
        ],
      ),
    );
  }
}

// ── Hero stats ────────────────────────────────────────────────────────────────

class _HeroStats extends StatelessWidget {
  const _HeroStats({
    required this.goal,
    required this.gc,
    required this.stats,
  });

  final Goal goal;
  final GoalColor gc;
  final ({int open, int total, int thisWeek}) stats;

  @override
  Widget build(BuildContext context) {
    final done = stats.total - stats.open;
    final progress = stats.total > 0 ? done / stats.total : 0.0;
    final progressPct = (progress * 100).round();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // PROGRESS
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PROGRESS',
                style: _labelStyle,
              ),
              const SizedBox(height: 4),
              Text(
                '$progressPct%',
                style: TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: gc.base,
                ),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.border.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation(gc.base),
                  minHeight: 5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.lg),

        // TASKS
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('TASKS', style: _labelStyle),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$done',
                      style: const TextStyle(
                        fontFamily: AppTypography.bodyFont,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextSpan(
                      text: '/${stats.total}',
                      style: const TextStyle(
                        fontFamily: AppTypography.bodyFont,
                        fontSize: 16,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${stats.thisWeek} this week',
                style: const TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.lg),

        // DEADLINE
        Expanded(
          child: _DeadlineStat(goal: goal),
        ),
      ],
    );
  }

  static const TextStyle _labelStyle = TextStyle(
    fontFamily: AppTypography.bodyFont,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColors.textMuted,
    letterSpacing: 0.8,
  );
}

// ── Status chip ───────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isArchived, required this.gc});

  final bool isArchived;
  final GoalColor gc;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isArchived ? AppColors.border : gc.base,
        ),
      ),
      child: Text(
        isArchived ? 'archived' : 'active',
        style: TextStyle(
          fontFamily: AppTypography.bodyFont,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: isArchived ? AppColors.textMuted : gc.base,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Deadline stat ─────────────────────────────────────────────────────────────

class _DeadlineStat extends StatelessWidget {
  const _DeadlineStat({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(
      fontFamily: AppTypography.bodyFont,
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: AppColors.textMuted,
      letterSpacing: 0.8,
    );

    final deadline = goal.deadline;
    if (deadline == null) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DEADLINE', style: labelStyle),
          SizedBox(height: 4),
          Text(
            '—',
            style: TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'No deadline',
            style: TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysLeft = deadline.difference(today).inDays;
    final daysLabel = daysLeft == 0
        ? 'Due today'
        : daysLeft > 0
            ? '$daysLeft days left'
            : '${daysLeft.abs()} days ago';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('DEADLINE', style: labelStyle),
        const SizedBox(height: 4),
        Text(
          DateFormat('MMM d').format(deadline),
          style: const TextStyle(
            fontFamily: AppTypography.bodyFont,
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          daysLabel,
          style: TextStyle(
            fontFamily: AppTypography.bodyFont,
            fontSize: 11,
            color: daysLeft < 0 ? AppColors.error : AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
