import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../goals/providers/goal_provider.dart' show goalColorMapProvider, Task;
import '../providers/today_provider.dart';
import '../../week/providers/week_provider.dart' show tasksForDateProvider;
import '../widgets/pending_section.dart';
import '../../shared/widgets/pressable.dart';
import '../widgets/task_form_sheet.dart';
import '../widgets/postpone_sheet.dart';
import '../widgets/task_tile.dart';
import '../../shared/widgets/delete_confirmation_dialog.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

class _MobileTodayView extends ConsumerStatefulWidget {
  const _MobileTodayView();

  @override
  ConsumerState<_MobileTodayView> createState() => _MobileTodayViewState();
}

class _MobileTodayViewState extends ConsumerState<_MobileTodayView> {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayOfWeek = DateFormat('EEEE').format(now).toUpperCase();
    final dateLabel = DateFormat('MMMM d').format(now);
    final tasksAsync = ref.watch(todayTasksProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline ribbon — always above header
        tasksAsync.when(
          data: (tasks) => Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
            child: _TimelineRibbon(tasks: tasks),
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: AppSpacing.md),
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              _NewTaskButton(onTap: () => showTaskForm(context)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: tasksAsync.when(
            data: (tasks) {
              if (tasks.isEmpty) return const _EmptyStateWithPending();
              return ListView(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: PendingSection(),
                  ),
                  _RightNowSection(tasks: tasks),
                  _ComingUpSection(tasks: tasks),
                ],
              );
            },
            loading: () => const _TaskListSkeleton(),
            error: (_, __) => const _EmptyState(),
          ),
        ),
      ],
    );
  }
}

/// Viewport width at which the sidebar appears.
const _sidebarBreakpoint = 1200.0;

/// Width of the contextual sidebar.
const _sidebarWidth = 260.0;

// ─── Desktop ─────────────────────────────────────────────────────────────────

class _DesktopTodayView extends ConsumerStatefulWidget {
  const _DesktopTodayView();

  @override
  ConsumerState<_DesktopTodayView> createState() => _DesktopTodayViewState();
}

class _DesktopTodayViewState extends ConsumerState<_DesktopTodayView> {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateLabel = DateFormat('EEEE · MMMM d').format(now);
    final tasksAsync = ref.watch(todayTasksProvider);
    final viewportWidth = MediaQuery.of(context).size.width;
    final showSidebar = viewportWidth >= _sidebarBreakpoint;

    final mainContent = SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxxl,
        AppSpacing.xxl,
        AppSpacing.xxxl,
        AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline ribbon — always above header
          tasksAsync.when(
            data: (tasks) => _TimelineRibbon(tasks: tasks),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "TODAY'S FOCUS",
                    style: TextStyle(
                      fontFamily: AppTypography.bodyFont,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateLabel,
                    style: const TextStyle(
                      fontFamily: AppTypography.displayFont,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),

          _NewTaskButton(onTap: () => showTaskForm(context)),
          const SizedBox(height: AppSpacing.lg),
          const PendingSection(),

          tasksAsync.when(
            data: (tasks) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _RightNowSection(tasks: tasks),
                _ComingUpSection(tasks: tasks),
              ],
            ),
            loading: () => const _TaskListSkeleton(),
            error: (_, __) => const _EmptyState(),
          ),
        ],
      ),
    );

    if (!showSidebar) return mainContent;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: mainContent),
        const _ContextSidebar(),
      ],
    );
  }
}

// ─── Timeline ribbon ──────────────────────────────────────────────────────────

class _TimelineRibbon extends ConsumerStatefulWidget {
  const _TimelineRibbon({required this.tasks});

  final List<Task> tasks;

  @override
  ConsumerState<_TimelineRibbon> createState() => _TimelineRibbonState();
}

class _TimelineRibbonState extends ConsumerState<_TimelineRibbon> {
  static const _startHour = 7;
  static const _endHour = 21;
  static const _totalMinutes = (_endHour - _startHour) * 60;
  static const _ribbonHeight = 62.0;
  static const _tickHours = [8, 10, 12, 14, 16, 18, 20];

  Timer? _timer;
  late int _nowMinutes;

  @override
  void initState() {
    super.initState();
    _nowMinutes = _currentMinutes();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _nowMinutes = _currentMinutes());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int _currentMinutes() {
    final now = DateTime.now();
    return now.hour * 60 + now.minute;
  }

  double _pct(int minutes) =>
      ((minutes - _startHour * 60) / _totalMinutes).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final timed = widget.tasks
        .where((t) => t.startTimeMinutes != null && t.endTimeMinutes != null)
        .toList();
    final nowMinutes = _nowMinutes;
    final goalColorMap = ref.watch(goalColorMapProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ribbon container
        Container(
          height: _ribbonHeight + 20, // +20 for hour labels above
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.5),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;

              Widget buildBlock(Task task) {
                final startMin = task.startTimeMinutes!;
                final endMin = task.endTimeMinutes!;
                final left = _pct(startMin) * totalWidth;
                final right = _pct(endMin) * totalWidth;
                final width = (right - left).clamp(16.0, double.infinity);

                final isPast = endMin <= nowMinutes;
                final isNow = startMin <= nowMinutes && nowMinutes < endMin;
                final gc = task.goalId != null
                    ? goalColorMap[task.goalId]
                    : null;
                final goalColor = gc?.base ?? AppColors.textMuted;

                return Positioned(
                  left: left,
                  width: width,
                  top: 24,
                  bottom: 4,
                  child: GestureDetector(
                    onTap: () => showTaskEditForm(context, task: task),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: isNow
                              ? goalColor.withValues(alpha: 0.9)
                              : isPast
                                  ? Colors.transparent
                                  : goalColor.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isNow
                                ? goalColor
                                : isPast
                                    ? goalColor.withValues(alpha: 0.3)
                                    : goalColor.withValues(alpha: 0.5),
                            style: BorderStyle.solid,
                          ),
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: isPast
                            ? CustomPaint(
                                painter: _HatchPainter(
                                  color: goalColor.withValues(alpha: 0.2),
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                child: Text(
                                  task.title,
                                  style: TextStyle(
                                    fontFamily: AppTypography.bodyFont,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: isNow
                                        ? AppColors.background
                                        : goalColor,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                      ),
                    ),
                  ),
                );
              }

              return Stack(
                children: [
                  // Hour ticks + labels
                  ..._tickHours.map((h) {
                    final x = _pct(h * 60) * totalWidth;
                    return Positioned(
                      left: x,
                      top: 0,
                      child: Column(
                        children: [
                          Text(
                            '${h > 12 ? h - 12 : h}${h >= 12 ? 'pm' : 'am'}',
                            style: const TextStyle(
                              fontFamily: AppTypography.bodyFont,
                              fontSize: 8,
                              color: AppColors.textMuted,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: _ribbonHeight,
                            color: AppColors.border.withValues(alpha: 0.4),
                          ),
                        ],
                      ),
                    );
                  }),

                  // Task blocks
                  ...timed.map(buildBlock),

                  // Now marker
                  if (nowMinutes >= _startHour * 60 &&
                      nowMinutes <= _endHour * 60)
                    Positioned(
                      left: _pct(nowMinutes) * totalWidth - 1,
                      top: 18,
                      bottom: 0,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(width: 2, color: Colors.white),
                          Positioned(
                            top: -5,
                            left: -4,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        // Goal legend
        const SizedBox(height: AppSpacing.sm),
        _GoalLegend(tasks: timed, goalColorMap: goalColorMap),
      ],
    );
  }
}

class _HatchPainter extends CustomPainter {
  const _HatchPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const step = 6.0;
    for (var i = -size.height; i < size.width; i += step) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HatchPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _GoalLegend extends StatelessWidget {
  const _GoalLegend({required this.tasks, required this.goalColorMap});

  final List<Task> tasks;
  final Map<String, dynamic> goalColorMap;

  @override
  Widget build(BuildContext context) {
    final seen = <String?>{};
    final entries = <(String?, Color)>[];

    for (final t in tasks) {
      if (!seen.contains(t.goalId)) {
        seen.add(t.goalId);
        final gc = t.goalId != null ? goalColorMap[t.goalId] : null;
        entries.add((t.goalId, gc?.base ?? AppColors.textMuted));
      }
    }
    if (entries.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: entries.map((e) {
        final (goalId, color) = e;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              goalId != null ? '★ Goal' : 'No goal',
              style: const TextStyle(
                fontFamily: AppTypography.bodyFont,
                fontSize: 10,
                color: AppColors.textMuted,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

// ─── Right now section ────────────────────────────────────────────────────────

class _RightNowSection extends ConsumerStatefulWidget {
  const _RightNowSection({required this.tasks});

  final List<Task> tasks;

  @override
  ConsumerState<_RightNowSection> createState() => _RightNowSectionState();
}

class _RightNowSectionState extends ConsumerState<_RightNowSection> {
  Future<void> _postpone(Task task) async {
    final picked = await showPostponeSheet(context);
    if (picked != null && mounted) {
      ref.read(taskActionsProvider.notifier).updateTask(
            task.copyWith(
              date: DateTime(picked.year, picked.month, picked.day),
            ),
          );
    }
  }

  Future<void> _cancel(Task task) async {
    final result = await showDeleteConfirmation(context, task);
    if (!mounted) return;
    if (result == DeleteResult.allFuture) {
      final sourceId = task.sourceTaskId ?? task.id;
      ref
          .read(taskActionsProvider.notifier)
          .deleteTask(sourceId, isRecurringSource: true);
    } else if (result == DeleteResult.thisInstance) {
      ref
          .read(taskActionsProvider.notifier)
          .deleteTask(task.id, isRecurringSource: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;

    final current = widget.tasks
        .where((t) =>
            t.startTimeMinutes != null &&
            t.endTimeMinutes != null &&
            t.startTimeMinutes! <= nowMinutes &&
            nowMinutes < t.endTimeMinutes!)
        .firstOrNull;

    if (current == null) return const SizedBox.shrink();

    final goalColorMap = ref.watch(goalColorMapProvider);
    final gc = current.goalId != null ? goalColorMap[current.goalId] : null;
    final goalColor = gc?.base ?? AppColors.golden;

    final endHour = current.endTimeMinutes! ~/ 60;
    final endMin = current.endTimeMinutes! % 60;
    final untilLabel =
        '${endHour > 12 ? endHour - 12 : endHour}:${endMin.toString().padLeft(2, '0')}${endHour >= 12 ? 'pm' : 'am'}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RIGHT NOW · UNTIL $untilLabel',
          style: const TextStyle(
            fontFamily: AppTypography.bodyFont,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: goalColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: goalColor.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      current.title,
                      style: const TextStyle(
                        fontFamily: AppTypography.bodyFont,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (current.goalId != null && gc != null)
                      Text(
                        '★ Goal',
                        style: TextStyle(
                          fontFamily: AppTypography.bodyFont,
                          fontSize: 11,
                          color: goalColor,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Done button
              Pressable(
                onTap: () => ref
                    .read(taskActionsProvider.notifier)
                    .toggleDone(current),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.golden,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Done ✓',
                    style: TextStyle(
                      fontFamily: AppTypography.bodyFont,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.background,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Postpone button
              Pressable(
                onTap: () => _postpone(current),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Text(
                    'Postpone →',
                    style: TextStyle(
                      fontFamily: AppTypography.bodyFont,
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              // Cancel button
              Pressable(
                onTap: () => _cancel(current),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: AppTypography.bodyFont,
                      fontSize: 12,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

// ─── Coming up section ────────────────────────────────────────────────────────

class _ComingUpSection extends ConsumerWidget {
  const _ComingUpSection({required this.tasks});

  final List<Task> tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;

    // Tasks that start after now, or have no time set and aren't done
    final upcoming = tasks.where((t) {
      if (t.done) return false;
      if (t.startTimeMinutes != null) return t.startTimeMinutes! > nowMinutes;
      // No time set: show in coming up if no current "right now" task
      return true;
    }).toList();

    // Also exclude current task from coming up
    upcoming.removeWhere((t) =>
        t.startTimeMinutes != null &&
        t.endTimeMinutes != null &&
        t.startTimeMinutes! <= nowMinutes &&
        nowMinutes < t.endTimeMinutes!);

    if (upcoming.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'COMING UP',
          style: TextStyle(
            fontFamily: AppTypography.bodyFont,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...upcoming.take(8).map((task) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: TaskTile(
                task: task,
                index: tasks.indexOf(task),
              ),
            )),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

// ─── New task button ──────────────────────────────────────────────────────────

class _NewTaskButton extends StatelessWidget {
  const _NewTaskButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      hoverColor: AppColors.golden.withValues(alpha: 0.08),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: AppColors.golden, size: 18),
            SizedBox(width: AppSpacing.sm),
            Text(
              'New task',
              style: TextStyle(
                fontFamily: AppTypography.bodyFont,
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ─── Task list skeleton ───────────────────────────────────────────────────────

class _TaskListSkeleton extends StatelessWidget {
  const _TaskListSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) => _SkeletonItem(delay: i * 80)),
    );
  }
}

class _SkeletonItem extends StatelessWidget {
  const _SkeletonItem({required this.delay});

  final int delay;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const SizedBox(width: AppSpacing.lg),
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xl),
          ],
        ),
      )
          .animate(delay: Duration(milliseconds: delay))
          .shimmer(
            duration: const Duration(milliseconds: 1200),
            color: AppColors.border,
          ),
    );
  }
}

// ─── Empty state with pending section ────────────────────────────────────────

class _EmptyStateWithPending extends StatelessWidget {
  const _EmptyStateWithPending();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      children: const [
        PendingSection(),
        _EmptyState(),
      ],
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

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

// ─── Context sidebar (desktop, > 1200px) ──────────────────────────────────────

class _ContextSidebar extends ConsumerWidget {
  const _ContextSidebar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayTasksAsync = ref.watch(todayTasksProvider);
    final pendingAsync = ref.watch(pendingTasksProvider);
    final streakAsync = ref.watch(todayStreakProvider);
    final goalColorMap = ref.watch(goalColorMapProvider);

    final upcoming = [
      for (int i = 1; i <= 3; i++) today.add(Duration(days: i)),
    ];

    return SizedBox(
      width: _sidebarWidth,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          0,
          AppSpacing.xxl,
          AppSpacing.xxl,
          AppSpacing.xxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Progress + per-goal bars ─────────────────────────────────────
            _SidebarCard(
              children: [
                const _SidebarSectionLabel("TODAY'S PROGRESS"),
                const SizedBox(height: AppSpacing.sm),
                todayTasksAsync.when(
                  data: (tasks) {
                    final done = tasks.where((t) => t.done).length;
                    final total = tasks.length;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ProgressBlock(done: done, total: total),
                        if (tasks.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.md),
                          ..._buildGoalBars(tasks, goalColorMap),
                        ],
                      ],
                    );
                  },
                  loading: () => const _SidebarPlaceholder(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Streak ────────────────────────────────────────────────────────
            _SidebarCard(
              children: [
                const _SidebarSectionLabel('STREAK'),
                const SizedBox(height: AppSpacing.sm),
                streakAsync.when(
                  data: (days) => _StreakBars(days: days),
                  loading: () => const _SidebarPlaceholder(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Overdue ───────────────────────────────────────────────────────
            pendingAsync.when(
              data: (pending) {
                if (pending.isEmpty) return const SizedBox.shrink();
                return Column(
                  children: [
                    _SidebarCard(
                      children: [
                        const _SidebarSectionLabel('OVERDUE'),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              size: 14,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              '${pending.length} task${pending.length == 1 ? '' : 's'} pending',
                              style: const TextStyle(
                                fontFamily: AppTypography.bodyFont,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                );
              },
              loading: () => const _TaskListSkeleton(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // ── Upcoming ──────────────────────────────────────────────────────
            _SidebarCard(
              children: [
                const _SidebarSectionLabel('UPCOMING'),
                const SizedBox(height: AppSpacing.sm),
                for (final day in upcoming) ...[
                  _UpcomingDayRow(date: day),
                  if (day != upcoming.last) const SizedBox(height: AppSpacing.xs),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGoalBars(
    List<Task> tasks,
    Map<String, dynamic> goalColorMap,
  ) {
    final byGoal = <String?, List<Task>>{};
    for (final t in tasks) {
      byGoal.putIfAbsent(t.goalId, () => []).add(t);
    }

    return byGoal.entries.map((e) {
      final goalId = e.key;
      final goalTasks = e.value;
      final done = goalTasks.where((t) => t.done).length;
      final total = goalTasks.length;
      final fraction = total == 0 ? 0.0 : done / total;
      final gc = goalId != null ? goalColorMap[goalId] : null;
      final color = gc?.base ?? AppColors.textMuted;

      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  goalId != null ? 'Goal' : 'No goal',
                  style: const TextStyle(
                    fontFamily: AppTypography.bodyFont,
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
                const Spacer(),
                Text(
                  '$done/$total',
                  style: const TextStyle(
                    fontFamily: AppTypography.bodyFont,
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 3,
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

// ─── Streak bars ──────────────────────────────────────────────────────────────

class _StreakBars extends StatelessWidget {
  const _StreakBars({required this.days});

  final List<({int done, int total})> days;

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    // Calculate streak count
    var streak = 0;
    for (var i = days.length - 1; i >= 0; i--) {
      if (days[i].done > 0) {
        streak++;
      } else {
        break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < days.length && i < _dayLabels.length; i++) ...[
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 24,
                      decoration: BoxDecoration(
                        color: _barColor(days[i]),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _dayLabels[i],
                      style: TextStyle(
                        fontFamily: AppTypography.bodyFont,
                        fontSize: 9,
                        color: i == days.length - 1
                            ? AppColors.golden
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (i < days.length - 1) const SizedBox(width: 3),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          streak == 0
              ? 'No streak yet — start today!'
              : '$streak-day streak — keep it alive',
          style: const TextStyle(
            fontFamily: AppTypography.bodyFont,
            fontSize: 11,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Color _barColor(({int done, int total}) day) {
    if (day.total == 0) return AppColors.border;
    final ratio = day.done / day.total;
    if (ratio >= 0.8) return AppColors.golden;
    if (ratio >= 0.5) return AppColors.golden.withValues(alpha: 0.5);
    return AppColors.golden.withValues(alpha: 0.25);
  }
}

// ─── Sidebar helpers ──────────────────────────────────────────────────────────

class _SidebarCard extends StatelessWidget {
  const _SidebarCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

class _SidebarSectionLabel extends StatelessWidget {
  const _SidebarSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: AppTypography.bodyFont,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _ProgressBlock extends StatelessWidget {
  const _ProgressBlock({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : done / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '$done',
              style: const TextStyle(
                fontFamily: AppTypography.bodyFont,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              ' / $total',
              style: const TextStyle(
                fontFamily: AppTypography.bodyFont,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 5,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation(AppColors.golden),
          ),
        ),
      ],
    );
  }
}

class _UpcomingDayRow extends ConsumerWidget {
  const _UpcomingDayRow({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksForDateProvider(date));
    final label = _dayLabel(date);

    return tasksAsync.when(
      data: (tasks) {
        final count = tasks.length;
        return Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Text(
              count == 0 ? '—' : '$count task${count == 1 ? '' : 's'}',
              style: TextStyle(
                fontFamily: AppTypography.bodyFont,
                fontSize: 12,
                color:
                    count == 0 ? AppColors.textMuted : AppColors.textPrimary,
                fontWeight:
                    count > 0 ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        );
      },
      loading: () => const _SidebarPlaceholder(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  static String _dayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = date.difference(today).inDays;
    if (diff == 1) return 'Tomorrow';
    return DateFormat('EEEE').format(date);
  }
}

class _SidebarPlaceholder extends StatelessWidget {
  const _SidebarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 14,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
