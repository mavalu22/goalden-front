import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/goal_provider.dart';
import '../widgets/goal_card.dart';
import '../widgets/goal_form_sheet.dart';

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

    final crossAxisCount = isDesktop ? 3 : 1;
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
                children: [
                  const Text(
                    'Goals',
                    style: TextStyle(
                      fontFamily: AppTypography.bodyFont,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
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

              return SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                ),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final goal = goals[i];
                      final taskCounts =
                          counts[goal.id] ?? (open: 0, total: 0);
                      return GoalCard(
                        goal: goal,
                        openTaskCount: taskCounts.open,
                        totalTaskCount: taskCounts.total,
                      );
                    },
                    childCount: goals.length,
                  ),
                  gridDelegate:
                      SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    childAspectRatio: isDesktop ? 1.8 : 2.2,
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
