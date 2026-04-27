import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/goal_colors.dart';
import '../providers/milestone_provider.dart';

class MilestonesPanel extends ConsumerStatefulWidget {
  const MilestonesPanel({
    super.key,
    required this.goalId,
    required this.gc,
  });

  final String goalId;
  final GoalColor gc;

  @override
  ConsumerState<MilestonesPanel> createState() => _MilestonesPanelState();
}

class _MilestonesPanelState extends ConsumerState<MilestonesPanel> {
  late final TextEditingController _newTitleCtrl;
  late final FocusNode _newFocusNode;
  DateTime _newDate = DateTime.now();
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _newTitleCtrl = TextEditingController();
    _newFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _newTitleCtrl.dispose();
    _newFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submitNew() async {
    final title = _newTitleCtrl.text.trim();
    if (title.isEmpty) return;
    if (_creating) return;
    setState(() => _creating = true);
    try {
      await ref
          .read(milestoneListProvider(widget.goalId).notifier)
          .createMilestone(
            goalId: widget.goalId,
            title: title,
            date: _newDate,
          );
      _newTitleCtrl.clear();
      setState(() => _newDate = DateTime.now());
      _newFocusNode.requestFocus();
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _pickNewDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _newDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.golden,
            surface: AppColors.surfaceElevated,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() => _newDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final milestonesAsync = ref.watch(milestonesForGoalProvider(widget.goalId));

    final gc = widget.gc;
    final goalId = widget.goalId;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          top: BorderSide(color: gc.base, width: 3),
          left: const BorderSide(color: AppColors.border),
          right: const BorderSide(color: AppColors.border),
          bottom: const BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Milestones',
                  style: TextStyle(
                    fontFamily: AppTypography.bodyFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: gc.base,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Important moments — big checkpoints on the way',
                  style: TextStyle(
                    fontFamily: AppTypography.bodyFont,
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // ── Milestones list ─────────────────────────────────────
          milestonesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.golden,
                  strokeWidth: 2,
                ),
              ),
            ),
            error: (_, __) => const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Text(
                'Failed to load milestones.',
                style: TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            data: (milestones) {
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final nextUpcomingIndex = milestones.indexWhere(
                (m) => !m.done && !m.date.isBefore(today),
              );

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  children: [
                    // Existing milestones — all pass isLast:false so line
                    // continues down to the create row.
                    for (int i = 0; i < milestones.length; i++)
                      _MilestoneRow(
                        milestone: milestones[i],
                        gc: gc,
                        isFirst: i == 0,
                        isLast: false,
                        isNextUpcoming: i == nextUpcomingIndex,
                        onToggle: () => ref
                            .read(milestoneListProvider(goalId).notifier)
                            .toggleDone(
                              milestones[i].id,
                              done: !milestones[i].done,
                            ),
                        onEdit: () =>
                            _showEditMilestoneDialog(context, ref, goalId, milestones[i]),
                        onDelete: () => ref
                            .read(milestoneListProvider(goalId).notifier)
                            .deleteMilestone(milestones[i].id),
                      ),

                    // Inline create row — always last.
                    _InlineCreateRow(
                      controller: _newTitleCtrl,
                      focusNode: _newFocusNode,
                      selectedDate: _newDate,
                      isFirst: milestones.isEmpty,
                      creating: _creating,
                      onSubmit: _submitNew,
                      onPickDate: _pickNewDate,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Milestone row ─────────────────────────────────────────────────────────────

class _MilestoneRow extends StatelessWidget {
  const _MilestoneRow({
    required this.milestone,
    required this.gc,
    required this.isFirst,
    required this.isLast,
    required this.isNextUpcoming,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final Milestone milestone;
  final GoalColor gc;
  final bool isFirst;
  final bool isLast;
  final bool isNextUpcoming;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDone = milestone.done;
    final markerSize = isLast ? 22.0 : 18.0;
    const lineColor = AppColors.border;

    return GestureDetector(
      onTap: onToggle,
      onLongPress: () => _showContextMenu(context),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Timeline column ────────────────────────────
                SizedBox(
                  width: 28,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Line above marker
                      if (!isFirst)
                        Expanded(
                          child: Center(
                            child: Container(
                              width: 1,
                              color: lineColor,
                            ),
                          ),
                        )
                      else
                        const SizedBox(height: AppSpacing.xs),

                      // Marker
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: markerSize,
                        height: markerSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone ? gc.base : Colors.transparent,
                          border: Border.all(
                            color: isDone
                                ? gc.base
                                : isNextUpcoming
                                    ? gc.base
                                    : AppColors.border,
                            width: isNextUpcoming && !isDone ? 2 : 1.5,
                          ),
                        ),
                        child: isDone
                            ? Icon(
                                Icons.check,
                                size: markerSize * 0.6,
                                color: AppColors.background,
                              )
                            : null,
                      ),

                      // Line below marker
                      if (!isLast)
                        Expanded(
                          child: Center(
                            child: Container(
                              width: 1,
                              color: lineColor,
                            ),
                          ),
                        )
                      else
                        const SizedBox(height: AppSpacing.xs),
                    ],
                  ),
                ),

                const SizedBox(width: AppSpacing.sm),

                // ── Content ─────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            milestone.title,
                            style: TextStyle(
                              fontFamily: AppTypography.bodyFont,
                              fontSize: isLast ? 14 : 13,
                              fontWeight: isLast
                                  ? FontWeight.w600
                                  : isNextUpcoming
                                      ? FontWeight.w500
                                      : FontWeight.w400,
                              color: isDone
                                  ? AppColors.textMuted
                                  : AppColors.textPrimary,
                              decoration: isDone
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              decorationColor: AppColors.textMuted,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          DateFormat('MMM d').format(milestone.date),
                          style: TextStyle(
                            fontFamily: AppTypography.bodyFont,
                            fontSize: 11,
                            color: isDone ? AppColors.textMuted : gc.base,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final box = context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      box.localToGlobal(Offset.zero, ancestor: overlay) &
          Size(box.size.width, box.size.height),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      color: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.border),
      ),
      items: [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 15, color: AppColors.textPrimary),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Edit',
                style: TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 15, color: AppColors.error),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Delete',
                style: TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 13,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'edit') onEdit();
      if (value == 'delete') onDelete();
    });
  }
}

// ── Inline create row ─────────────────────────────────────────────────────────

class _InlineCreateRow extends StatelessWidget {
  const _InlineCreateRow({
    required this.controller,
    required this.focusNode,
    required this.selectedDate,
    required this.isFirst,
    required this.creating,
    required this.onSubmit,
    required this.onPickDate,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final DateTime selectedDate;
  final bool isFirst;
  final bool creating;
  final VoidCallback onSubmit;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Dashed marker column ───────────────────────────
            SizedBox(
              width: 28,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Line above (connects to the last milestone)
                  if (!isFirst)
                    Expanded(
                      child: Center(
                        child: Container(width: 1, color: AppColors.border),
                      ),
                    )
                  else
                    const SizedBox(height: AppSpacing.xs),

                  // Dashed circle marker
                  CustomPaint(
                    size: const Size(18, 18),
                    painter: _DashedCirclePainter(),
                    child: const SizedBox(width: 18, height: 18),
                  ),

                  // No line below (this is always last)
                  const SizedBox(height: AppSpacing.xs),
                ],
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            // ── Input row ──────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        style: const TextStyle(
                          fontFamily: AppTypography.bodyFont,
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'New milestone…',
                          hintStyle: TextStyle(
                            fontFamily: AppTypography.bodyFont,
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onSubmitted: (_) => onSubmit(),
                        textInputAction: TextInputAction.done,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    // Date picker button
                    GestureDetector(
                      onTap: onPickDate,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Text(
                          DateFormat('MMM d').format(selectedDate),
                          style: const TextStyle(
                            fontFamily: AppTypography.bodyFont,
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    GestureDetector(
                      onTap: creating ? null : onSubmit,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Icon(
                          Icons.add_circle_outline,
                          size: 16,
                          color: creating
                              ? AppColors.textMuted
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Paints a dashed circle outline.
class _DashedCirclePainter extends CustomPainter {
  _DashedCirclePainter();

  @override
  void paint(Canvas canvas, Size size) {
    const dashCount = 8;
    const gapFraction = 0.4;
    final paint = Paint()
      ..color = AppColors.textMuted
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1;
    const totalAngle = 2 * 3.14159265;
    const dashAngle = totalAngle / dashCount * (1 - gapFraction);
    const gapAngle = totalAngle / dashCount * gapFraction;

    double startAngle = -3.14159265 / 2;
    for (int i = 0; i < dashCount; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle,
        false,
        paint,
      );
      startAngle += dashAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter oldDelegate) => false;
}

// ── Edit milestone dialog ─────────────────────────────────────────────────────

Future<void> _showEditMilestoneDialog(
  BuildContext context,
  WidgetRef ref,
  String goalId,
  Milestone milestone,
) async {
  final titleCtrl = TextEditingController(text: milestone.title);
  DateTime selectedDate = milestone.date;
  String? titleError;

  await showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => Dialog(
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
                'Edit milestone',
                style: TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Title
              const Text(
                'Title',
                style: TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Material(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                child: TextField(
                  controller: titleCtrl,
                  autofocus: true,
                  style: const TextStyle(
                    fontFamily: AppTypography.bodyFont,
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(AppSpacing.md),
                    errorText: titleError,
                    errorStyle: const TextStyle(color: AppColors.error),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Date
              const Text(
                'Date',
                style: TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                    builder: (c, child) => Theme(
                      data: Theme.of(c).copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: AppColors.golden,
                          surface: AppColors.surfaceElevated,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) setState(() => selectedDate = picked);
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          DateFormat('MMMM d, y').format(selectedDate),
                          style: const TextStyle(
                            fontFamily: AppTypography.bodyFont,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: AppTypography.bodyFont,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final title = titleCtrl.text.trim();
                        if (title.isEmpty) {
                          setState(() => titleError = 'Title is required.');
                          return;
                        }
                        await ref
                            .read(milestoneListProvider(goalId).notifier)
                            .updateMilestone(
                              milestone.copyWith(
                                title: title,
                                date: selectedDate,
                              ),
                            );
                        if (ctx.mounted) Navigator.of(ctx).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.golden,
                        foregroundColor: AppColors.background,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md),
                      ),
                      child: const Text(
                        'Save',
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
    ),
  );
  titleCtrl.dispose();
}
