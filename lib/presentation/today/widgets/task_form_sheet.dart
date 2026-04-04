import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/models/task.dart';
import '../../shared/widgets/pressable.dart';
import '../providers/today_provider.dart';

/// Opens the task creation form. Pass [defaultDate] to pre-fill the date.
Future<void> showTaskForm(
  BuildContext context, {
  DateTime? defaultDate,
}) =>
    _show(context, task: null, defaultDate: defaultDate);

/// Opens the task editing form pre-filled with [task]'s current values.
Future<void> showTaskEditForm(
  BuildContext context, {
  required Task task,
}) =>
    _show(context, task: task);

Future<void> _show(
  BuildContext context, {
  Task? task,
  DateTime? defaultDate,
}) async {
  final isDesktop =
      MediaQuery.of(context).size.width >= AppConstants.mobileBreakpoint;

  if (isDesktop) {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _TaskFormDialog(task: task, defaultDate: defaultDate),
    );
  } else {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TaskFormSheet(task: task, defaultDate: defaultDate),
    );
  }
}

// ─── Mobile bottom sheet wrapper ──────────────────────────────────────────────

class _TaskFormSheet extends StatelessWidget {
  const _TaskFormSheet({this.task, this.defaultDate});

  final Task? task;
  final DateTime? defaultDate;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: _TaskFormContent(
            task: task,
            defaultDate: defaultDate,
            scrollController: controller,
          ),
        ),
      ),
    );
  }
}

// ─── Desktop dialog wrapper ───────────────────────────────────────────────────

class _TaskFormDialog extends StatelessWidget {
  const _TaskFormDialog({this.task, this.defaultDate});

  final Task? task;
  final DateTime? defaultDate;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          width: 480,
          margin: const EdgeInsets.all(AppSpacing.xxl),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: _TaskFormContent(task: task, defaultDate: defaultDate),
          ),
        ),
      ),
    );
  }
}

// ─── Form content ─────────────────────────────────────────────────────────────

class _TaskFormContent extends ConsumerStatefulWidget {
  const _TaskFormContent({this.task, this.defaultDate, this.scrollController});

  final Task? task;
  final DateTime? defaultDate;
  final ScrollController? scrollController;

  @override
  ConsumerState<_TaskFormContent> createState() => _TaskFormContentState();
}

class _TaskFormContentState extends ConsumerState<_TaskFormContent> {
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  final _titleFocusNode = FocusNode();

  late DateTime _selectedDate;
  late TaskPriority _priority;
  late TaskRecurrence _recurrence;
  late Set<int> _recurrenceDays;

  bool _isSubmitting = false;
  bool get _isEditing => widget.task != null;

  bool get _isDirty {
    if (_isEditing) {
      final t = widget.task!;
      return _titleController.text.trim() != t.title ||
          _noteController.text.trim() != (t.note ?? '') ||
          _selectedDate != t.date ||
          _priority != t.priority ||
          _recurrence != t.recurrence ||
          !_setEquals(_recurrenceDays, Set<int>.from(t.recurrenceDays));
    }
    // Create mode: dirty if the user typed anything in the title
    return _titleController.text.trim().isNotEmpty;
  }

  bool _setEquals(Set<int> a, Set<int> b) =>
      a.length == b.length && a.containsAll(b);

  Future<void> _tryClose() async {
    if (!_isDirty) {
      Navigator.of(context).pop();
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Text(
          'Discard changes?',
          style: TextStyle(
            fontFamily: AppTypography.bodyFont,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: const Text(
          'Your changes will not be saved.',
          style: TextStyle(
            fontFamily: AppTypography.bodyFont,
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Keep editing',
              style: TextStyle(
                fontFamily: AppTypography.bodyFont,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Discard',
              style: TextStyle(
                fontFamily: AppTypography.bodyFont,
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    if (t != null) {
      // Pre-fill for edit mode
      _titleController.text = t.title;
      _noteController.text = t.note ?? '';
      _selectedDate = t.date;
      _priority = t.priority;
      _recurrence = t.recurrence;
      _recurrenceDays = Set<int>.from(t.recurrenceDays);
    } else {
      // Defaults for create mode
      final now = DateTime.now();
      _selectedDate =
          widget.defaultDate ?? DateTime(now.year, now.month, now.day);
      _priority = TaskPriority.normal;
      _recurrence = TaskRecurrence.none;
      _recurrenceDays = {};
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _titleFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.golden,
            surface: AppColors.surface,
            onSurface: AppColors.textPrimary,
          ),
          dialogTheme: const DialogThemeData(
            backgroundColor: AppColors.background,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) {
      _titleFocusNode.requestFocus();
      return;
    }
    setState(() => _isSubmitting = true);

    final note = _noteController.text.trim().isEmpty
        ? null
        : _noteController.text.trim();
    final days = _recurrenceDays.toList()..sort();

    if (_isEditing) {
      await ref.read(taskActionsProvider.notifier).updateTask(
            widget.task!.copyWith(
              title: _titleController.text.trim(),
              date: _selectedDate,
              priority: _priority,
              note: note,
              recurrence: _recurrence,
              recurrenceDays: days,
            ),
          );
    } else {
      await ref.read(taskActionsProvider.notifier).createTask(
            _titleController.text.trim(),
            date: _selectedDate,
            priority: _priority,
            note: note,
            recurrence: _recurrence,
            recurrenceDays: days,
          );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _tryClose();
      },
      child: ListView(
      controller: widget.scrollController,
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xxl,
      ),
      children: [
        // Handle (mobile only)
        if (widget.scrollController != null)
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        // Header row: title + close button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              _isEditing ? 'Edit Task' : 'New Task',
              style: const TextStyle(
                fontFamily: AppTypography.displayFont,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Pressable(
              onTap: _tryClose,
              borderRadius: BorderRadius.circular(20),
              hoverColor: AppColors.textMuted.withValues(alpha: 0.1),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.close,
                  size: 20,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),

        // Title field
        const _FieldLabel('Title'),
        const SizedBox(height: AppSpacing.xs),
        _inputContainer(
          child: TextField(
            controller: _titleController,
            focusNode: _titleFocusNode,
            style: _inputTextStyle,
            decoration: _inputDecoration('What needs to be done?'),
            textInputAction: TextInputAction.next,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Date field
        const _FieldLabel('Date'),
        const SizedBox(height: AppSpacing.xs),
        Pressable(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(12),
          hoverColor: AppColors.golden.withValues(alpha: 0.06),
          child: _inputContainer(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 16, color: AppColors.textMuted),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    DateFormat('EEEE, MMMM d').format(_selectedDate),
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
        const SizedBox(height: AppSpacing.lg),

        // Priority field
        const _FieldLabel('Priority'),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            _PriorityButton(
              label: 'Normal',
              selected: _priority == TaskPriority.normal,
              onTap: () => setState(() => _priority = TaskPriority.normal),
            ),
            const SizedBox(width: AppSpacing.sm),
            _PriorityButton(
              label: 'High',
              selected: _priority == TaskPriority.high,
              onTap: () => setState(() => _priority = TaskPriority.high),
              isHigh: true,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Note field
        const _FieldLabel('Note'),
        const SizedBox(height: AppSpacing.xs),
        _inputContainer(
          child: TextField(
            controller: _noteController,
            style: _inputTextStyle,
            decoration: _inputDecoration('Add a note... (optional)'),
            maxLines: 3,
            minLines: 3,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Recurrence field
        const _FieldLabel('Repeat'),
        const SizedBox(height: AppSpacing.xs),
        _RecurrenceSelector(
          value: _recurrence,
          onChanged: (r) => setState(() {
            _recurrence = r;
            if (r != TaskRecurrence.customDays) _recurrenceDays.clear();
          }),
        ),
        if (_recurrence == TaskRecurrence.customDays) ...[
          const SizedBox(height: AppSpacing.md),
          _DayOfWeekPicker(
            selected: _recurrenceDays,
            onToggle: (day) => setState(() {
              if (_recurrenceDays.contains(day)) {
                _recurrenceDays.remove(day);
              } else {
                _recurrenceDays.add(day);
              }
            }),
          ),
        ],
        const SizedBox(height: AppSpacing.xxxl),

        // Save/Create button
        Pressable(
          onTap: _isSubmitting ? null : _submit,
          borderRadius: BorderRadius.circular(14),
          hoverColor: Colors.white.withValues(alpha: 0.1),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.golden,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation(AppColors.background),
                      ),
                    )
                  : Text(
                      _isEditing ? 'Save Changes' : 'Create Task',
                      style: const TextStyle(
                        fontFamily: AppTypography.bodyFont,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.background,
                      ),
                    ),
            ),
          ),
        ),
      ],
      ),  // ListView
    );  // PopScope
  }

  Widget _inputContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }

  static const _inputTextStyle = TextStyle(
    fontFamily: AppTypography.bodyFont,
    fontSize: 14,
    color: AppColors.textPrimary,
  );

  static InputDecoration _inputDecoration(String hint) => InputDecoration(
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
      );
}

// ─── Field label ──────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontFamily: AppTypography.bodyFont,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
        letterSpacing: 1.0,
      ),
    );
  }
}

// ─── Priority button ──────────────────────────────────────────────────────────

class _PriorityButton extends StatelessWidget {
  const _PriorityButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.isHigh = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isHigh;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      hoverColor: isHigh
          ? AppColors.golden.withValues(alpha: 0.08)
          : AppColors.textSecondary.withValues(alpha: 0.08),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected
              ? (isHigh ? AppColors.goldenDim : AppColors.surface)
              : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? (isHigh ? AppColors.goldenBorder : AppColors.textSecondary)
                : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isHigh)
              Icon(
                Icons.flag_outlined,
                size: 14,
                color: selected ? AppColors.golden : AppColors.textMuted,
              ),
            if (isHigh) const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTypography.bodyFont,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected
                    ? (isHigh ? AppColors.golden : AppColors.textPrimary)
                    : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Recurrence selector ──────────────────────────────────────────────────────

class _RecurrenceSelector extends StatelessWidget {
  const _RecurrenceSelector({
    required this.value,
    required this.onChanged,
  });

  final TaskRecurrence value;
  final ValueChanged<TaskRecurrence> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _RecurrenceChip(
          label: 'None',
          selected: value == TaskRecurrence.none,
          onTap: () => onChanged(TaskRecurrence.none),
        ),
        _RecurrenceChip(
          label: 'Daily',
          selected: value == TaskRecurrence.daily,
          onTap: () => onChanged(TaskRecurrence.daily),
        ),
        _RecurrenceChip(
          label: 'Weekly',
          selected: value == TaskRecurrence.weekly,
          onTap: () => onChanged(TaskRecurrence.weekly),
        ),
        _RecurrenceChip(
          label: 'Custom days',
          selected: value == TaskRecurrence.customDays,
          onTap: () => onChanged(TaskRecurrence.customDays),
        ),
      ],
    );
  }
}

class _RecurrenceChip extends StatelessWidget {
  const _RecurrenceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      hoverColor: AppColors.golden.withValues(alpha: 0.08),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.goldenDim : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.goldenBorder : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTypography.bodyFont,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? AppColors.golden : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

// ─── Day-of-week picker ───────────────────────────────────────────────────────

class _DayOfWeekPicker extends StatelessWidget {
  const _DayOfWeekPicker({
    required this.selected,
    required this.onToggle,
  });

  final Set<int> selected;
  final ValueChanged<int> onToggle;

  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (int i = 0; i < 7; i++)
          Pressable(
            onTap: () => onToggle(i + 1),
            scaleFactor: 0.9,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected.contains(i + 1)
                    ? AppColors.golden
                    : AppColors.background,
                border: Border.all(
                  color: selected.contains(i + 1)
                      ? AppColors.golden
                      : AppColors.border,
                ),
              ),
              child: Center(
                child: Text(
                  _days[i],
                  style: TextStyle(
                    fontFamily: AppTypography.bodyFont,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected.contains(i + 1)
                        ? AppColors.background
                        : AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
