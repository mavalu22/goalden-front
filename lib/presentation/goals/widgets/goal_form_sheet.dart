import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/goal_colors.dart';
import '../providers/goal_provider.dart';

/// Opens the new-goal creation form.
Future<void> showGoalForm(BuildContext context) =>
    _show(context, goal: null);

/// Opens the goal editing form pre-filled with [goal]'s current values.
Future<void> showGoalEditForm(BuildContext context, {required Goal goal}) =>
    _show(context, goal: goal);

Future<void> _show(BuildContext context, {Goal? goal}) async {
  final isDesktop =
      MediaQuery.of(context).size.width >= AppConstants.mobileBreakpoint;

  if (isDesktop) {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _GoalFormDialog(goal: goal),
    );
  } else {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GoalFormSheet(goal: goal),
    );
  }
}

// ─── Mobile bottom sheet ──────────────────────────────────────────────────────

class _GoalFormSheet extends StatelessWidget {
  const _GoalFormSheet({this.goal});

  final Goal? goal;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: _GoalFormContent(goal: goal, scrollController: controller),
        ),
      ),
    );
  }
}

// ─── Desktop dialog ───────────────────────────────────────────────────────────

class _GoalFormDialog extends StatelessWidget {
  const _GoalFormDialog({this.goal});

  final Goal? goal;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 480,
        child: _GoalFormContent(goal: goal),
      ),
    );
  }
}

// ─── Shared form content ──────────────────────────────────────────────────────

class _GoalFormContent extends ConsumerStatefulWidget {
  const _GoalFormContent({this.goal, this.scrollController});

  final Goal? goal;
  final ScrollController? scrollController;

  @override
  ConsumerState<_GoalFormContent> createState() => _GoalFormContentState();
}

class _GoalFormContentState extends ConsumerState<_GoalFormContent> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late String _selectedColorId;
  DateTime? _deadline;
  bool _saving = false;
  String? _titleError;

  @override
  void initState() {
    super.initState();
    final g = widget.goal;
    _titleCtrl = TextEditingController(text: g?.title ?? '');
    _descCtrl = TextEditingController(text: g?.description ?? '');
    _selectedColorId = g?.color ?? GoalColors.palette.first.id;
    _deadline = g?.deadline;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.goal != null;

  void _validate() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = 'Title is required.');
    } else if (title.length > 500) {
      setState(() => _titleError = 'Title is too long.');
    } else {
      setState(() => _titleError = null);
    }
  }

  Future<void> _save() async {
    _validate();
    if (_titleError != null) return;

    setState(() => _saving = true);
    try {
      final notifier = ref.read(goalListProvider.notifier);
      if (_isEditing) {
        final updated = widget.goal!.copyWith(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
          color: _selectedColorId,
          starred: true,
          deadline: _deadline,
        );
        await notifier.updateGoal(updated);
      } else {
        await notifier.createGoal(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
          color: _selectedColorId,
          deadline: _deadline,
          starred: true,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.golden,
            surface: AppColors.surfaceElevated,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEditing ? 'Edit Goal' : 'New Goal';

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        // ── Close + title row ─────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close,
                  color: AppColors.textSecondary, size: 20),
              visualDensity: VisualDensity.compact,
              tooltip: 'Cancel',
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.xl),

        // ── Title ─────────────────────────────────────────────────
        _label('Title'),
        const SizedBox(height: AppSpacing.xs),
        Material(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          child: TextField(
            controller: _titleCtrl,
            autofocus: !_isEditing,
            style: const TextStyle(
              fontFamily: AppTypography.bodyFont,
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'e.g. Launch product by Q3',
              hintStyle: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(AppSpacing.md),
              errorText: _titleError,
              errorStyle: const TextStyle(color: AppColors.error),
            ),
            onChanged: (_) {
              if (_titleError != null) _validate();
            },
            onSubmitted: (_) => _save(),
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // ── Description ───────────────────────────────────────────
        _label('Description (optional)'),
        const SizedBox(height: AppSpacing.xs),
        Material(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          child: TextField(
            controller: _descCtrl,
            maxLines: 3,
            style: const TextStyle(
              fontFamily: AppTypography.bodyFont,
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
            decoration: const InputDecoration(
              hintText: 'What does success look like?',
              hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(AppSpacing.md),
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // ── Color picker ──────────────────────────────────────────
        _label('Color'),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: GoalColors.palette.map((gc) {
            final selected = _selectedColorId == gc.id;
            return GestureDetector(
              onTap: () => setState(() => _selectedColorId = gc.id),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: gc.base,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? AppColors.textPrimary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? const Icon(Icons.check,
                          size: 14, color: AppColors.background)
                      : null,
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: AppSpacing.lg),

        // ── Deadline ──────────────────────────────────────────────
        _label('Deadline (optional)'),
        const SizedBox(height: AppSpacing.xs),
        GestureDetector(
          onTap: _pickDeadline,
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
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    _deadline != null
                        ? DateFormat('MMMM d, y').format(_deadline!)
                        : 'No deadline',
                    style: TextStyle(
                      fontFamily: AppTypography.bodyFont,
                      fontSize: 14,
                      color: _deadline != null
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ),
                  ),
                  const Spacer(),
                  if (_deadline != null)
                    GestureDetector(
                      onTap: () => setState(() => _deadline = null),
                      child: const Icon(Icons.close,
                          size: 14, color: AppColors.textMuted),
                    ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.xxxl),

        // ── Save button ───────────────────────────────────────────
        SizedBox(
          height: 44,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.golden,
              foregroundColor: AppColors.background,
              disabledBackgroundColor: AppColors.goldenDim,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.background,
                    ),
                  )
                : Text(
                    _isEditing ? 'Save changes' : 'Create',
                    style: const TextStyle(
                      fontFamily: AppTypography.bodyFont,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontFamily: AppTypography.bodyFont,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
          letterSpacing: 0.3,
        ),
      );
}
