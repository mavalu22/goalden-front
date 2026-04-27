import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/goal_provider.dart';
import '../widgets/goal_card.dart' show GoalCard, GoalEmptySlot;
import '../widgets/goal_form_sheet.dart';
import 'goal_detail_screen.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop =
            constraints.maxWidth >= AppConstants.mobileBreakpoint;
        return _GoalsView(isDesktop: isDesktop);
      },
    );
  }
}

class _GoalsView extends ConsumerWidget {
  const _GoalsView({required this.isDesktop});

  final bool isDesktop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showArchived = ref.watch(showArchivedGoalsProvider);
    final goalsAsync = showArchived
        ? ref.watch(archivedGoalsProvider)
        : ref.watch(activeGoalsProvider);
    final countsAsync = ref.watch(goalTaskCountsProvider);

    final crossAxisCount = isDesktop ? 2 : 1;
    final horizontalPadding =
        isDesktop ? AppSpacing.xxxl : AppSpacing.lg;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                AppSpacing.xl,
                horizontalPadding,
                0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'YOUR GOALS',
                        style: TextStyle(
                          fontFamily: AppTypography.bodyFont,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                          letterSpacing: 1.2,
                        ),
                      ),
                      goalsAsync.when(
                        data: (goals) {
                          final active = goals
                              .where((g) => g.status == GoalStatus.active)
                              .length;
                          return Text(
                            '$active active',
                            style: const TextStyle(
                              fontFamily: AppTypography.displayFont,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _NewGoalButton(),
                ],
              ),
            ),
          ),

          // ── Filter chips ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                AppSpacing.md,
                horizontalPadding,
                AppSpacing.lg,
              ),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Active',
                    selected: !showArchived,
                    onTap: () => ref
                        .read(showArchivedGoalsProvider.notifier)
                        .state = false,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _FilterChip(
                    label: 'Archived',
                    selected: showArchived,
                    onTap: () => ref
                        .read(showArchivedGoalsProvider.notifier)
                        .state = true,
                  ),
                ],
              ),
            ),
          ),

          // ── Goals grid ───────────────────────────────────────────
          goalsAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: _LoadingState(),
            ),
            error: (_, __) => const SliverToBoxAdapter(
              child: _ErrorState(),
            ),
            data: (goals) {
              if (goals.isEmpty) {
                return SliverToBoxAdapter(
                  child: _EmptyState(showArchived: showArchived),
                );
              }

              final counts = countsAsync.valueOrNull ?? {};

              // +1 for the empty slot
              final itemCount = goals.length + 1;
              return SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                ),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      // Last item is the empty slot
                      if (i == goals.length) {
                        return GoalEmptySlot(
                          onTap: () => showGoalForm(context),
                        );
                      }
                      final goal = goals[i];
                      final taskCounts =
                          counts[goal.id] ?? (open: 0, total: 0);
                      return GoalCard(
                        goal: goal,
                        openTaskCount: taskCounts.open,
                        totalTaskCount: taskCounts.total,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => GoalDetailScreen(goal: goal),
                          ),
                        ),
                        onEdit: () =>
                            showGoalEditForm(context, goal: goal),
                        onToggleStar: () => ref
                            .read(goalListProvider.notifier)
                            .updateGoal(
                              goal.copyWith(starred: !goal.starred),
                            ),
                        onArchive: () {
                          final notifier =
                              ref.read(goalListProvider.notifier);
                          if (goal.status == GoalStatus.archived) {
                            notifier.unarchiveGoal(goal.id);
                          } else {
                            notifier.archiveGoal(goal.id);
                          }
                        },
                        onDelete: () =>
                            _confirmDeleteGoal(context, ref, goal),
                      );
                    },
                    childCount: itemCount,
                  ),
                  gridDelegate:
                      SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    childAspectRatio: isDesktop ? 1.6 : 1.4,
                  ),
                ),
              );
            },
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.huge),
          ),
        ],
      ),
    );
  }
}

// ── Goal delete confirmation ──────────────────────────────────────────────────

Future<void> _confirmDeleteGoal(
  BuildContext context,
  WidgetRef ref,
  Goal goal,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Delete goal',
              style: TextStyle(
                fontFamily: AppTypography.bodyFont,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Are you sure you want to delete this goal? Linked tasks will be unlinked but not deleted. This cannot be undone.',
              style: TextStyle(
                fontFamily: AppTypography.bodyFont,
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontFamily: AppTypography.bodyFont,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(
                        fontFamily: AppTypography.bodyFont,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  if (confirmed == true && context.mounted) {
    await ref.read(goalListProvider.notifier).deleteGoal(goal.id);
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _NewGoalButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => showGoalForm(context),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.golden,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, color: AppColors.background, size: 16),
              SizedBox(width: AppSpacing.xs),
              Text(
                'New goal',
                style: TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.background,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.goldenDim : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppColors.goldenBorder
                  : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: 12,
              fontWeight:
                  selected ? FontWeight.w600 : FontWeight.w400,
              color: selected
                  ? AppColors.golden
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.showArchived});

  final bool showArchived;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.huge),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.massive),
          Icon(
            showArchived ? Icons.archive_outlined : Icons.star_outline,
            size: 48,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            showArchived
                ? 'No archived goals yet.'
                : 'No goals yet.',
            style: const TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            showArchived
                ? 'Goals you archive will appear here.'
                : 'Set your first goal and start making progress.',
            style: const TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (!showArchived) ...[
            const SizedBox(height: AppSpacing.xl),
            Builder(builder: (ctx) => _NewGoalButton()),
          ],
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.massive),
      child: Center(
        child: CircularProgressIndicator(
          color: AppColors.golden,
          strokeWidth: 2,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.massive),
      child: Center(
        child: Text(
          'Failed to load goals.',
          style: TextStyle(
            fontFamily: AppTypography.bodyFont,
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
