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
    final statsAsync = ref.watch(goalDetailStatsProvider(goal.id));

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

                  // Hero card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding),
                      child: _HeroCard(
                        goal: liveGoal,
                        gc: gc,
                        ref: ref,
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
                      child: SizedBox(height: AppSpacing.lg)),

                  // Stats row
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding),
                      child: statsAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (stats) => _StatsRow(
                          goal: liveGoal,
                          gc: gc,
                          open: stats.open,
                          total: stats.total,
                          thisWeek: stats.thisWeek,
                        ),
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
    required this.ref,
    required this.onEdit,
    required this.onArchive,
  });

  final Goal goal;
  final GoalColor gc;
  final WidgetRef ref;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final isArchived = goal.status == GoalStatus.archived;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: gc.soft,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: gc.base, width: 3),
          top: const BorderSide(color: AppColors.border),
          right: const BorderSide(color: AppColors.border),
          bottom: const BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (goal.starred) ...[
                Icon(Icons.star_rounded, color: gc.base, size: 18),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Text(
                  goal.title,
                  style: const TextStyle(
                    fontFamily: AppTypography.bodyFont,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Status chip + action buttons
          Row(
            children: [
              _StatusChip(isArchived: isArchived),
              const Spacer(),
              _ActionButton(
                label: 'Edit',
                icon: Icons.edit_outlined,
                onTap: onEdit,
              ),
              const SizedBox(width: AppSpacing.sm),
              _ActionButton(
                label: isArchived ? 'Unarchive' : 'Archive',
                icon: isArchived
                    ? Icons.unarchive_outlined
                    : Icons.archive_outlined,
                onTap: onArchive,
              ),
            ],
          ),

          // Description
          if (goal.description != null && goal.description!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              goal.description!,
              style: const TextStyle(
                fontFamily: AppTypography.bodyFont,
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isArchived});

  final bool isArchived;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isArchived ? AppColors.surfaceElevated : AppColors.goldenDim,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isArchived ? AppColors.border : AppColors.goldenBorder,
        ),
      ),
      child: Text(
        isArchived ? 'Archived' : 'Active',
        style: TextStyle(
          fontFamily: AppTypography.bodyFont,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isArchived ? AppColors.textMuted : AppColors.golden,
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

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.goal,
    required this.gc,
    required this.open,
    required this.total,
    required this.thisWeek,
  });

  final Goal goal;
  final GoalColor gc;
  final int open;
  final int total;
  final int thisWeek;

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? (total - open) / total : 0.0;
    final progressPct = (progress * 100).round();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatCell(
              label: 'PROGRESS',
              value: '$progressPct%',
              sub: _ProgressBar(progress: progress, gc: gc),
            ),
          ),
          Container(
            width: 1,
            height: 48,
            color: AppColors.border,
          ),
          Expanded(
            child: _StatCell(
              label: 'TASKS',
              value: '$open / $total',
              subText: '$thisWeek this week',
            ),
          ),
          Container(
            width: 1,
            height: 48,
            color: AppColors.border,
          ),
          Expanded(
            child: _DeadlineStat(goal: goal, gc: gc),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    this.subText,
    this.sub,
  });

  final String label;
  final String value;
  final String? subText;
  final Widget? sub;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: const TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (sub != null) ...[
            const SizedBox(height: AppSpacing.xs),
            sub!,
          ] else if (subText != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              subText!,
              style: const TextStyle(
                fontFamily: AppTypography.bodyFont,
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress, required this.gc});

  final double progress;
  final GoalColor gc;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: progress,
        backgroundColor: AppColors.border,
        valueColor: AlwaysStoppedAnimation(gc.base),
        minHeight: 3,
      ),
    );
  }
}

class _DeadlineStat extends StatelessWidget {
  const _DeadlineStat({required this.goal, required this.gc});

  final Goal goal;
  final GoalColor gc;

  @override
  Widget build(BuildContext context) {
    final deadline = goal.deadline;
    if (deadline == null) {
      return const _StatCell(
        label: 'DEADLINE',
        value: '—',
        subText: 'No deadline',
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'DEADLINE',
            style: TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            DateFormat('MMM d').format(deadline),
            style: const TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            daysLabel,
            style: TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: 11,
              color: daysLeft < 0 ? AppColors.error : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

