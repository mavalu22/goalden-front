import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/goal_colors.dart' show GoalColors;
import '../../../domain/models/task.dart' show TaskRecurrence;
import '../../goals/providers/goal_provider.dart';
import '../../shared/widgets/pressable.dart';
import '../providers/today_provider.dart';

/// Opens the task creation form. Pass [defaultDate] and/or [defaultGoalId] to pre-fill.
Future<void> showTaskForm(
  BuildContext context, {
  DateTime? defaultDate,
  String? defaultGoalId,
}) =>
    _show(context, task: null, defaultDate: defaultDate, defaultGoalId: defaultGoalId);

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
  String? defaultGoalId,
}) async {
  final isDesktop =
      MediaQuery.of(context).size.width >= AppConstants.mobileBreakpoint;

  if (isDesktop) {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _TaskFormDialog(task: task, defaultDate: defaultDate, defaultGoalId: defaultGoalId),
    );
  } else {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TaskFormSheet(task: task, defaultDate: defaultDate, defaultGoalId: defaultGoalId),
    );
  }
}

// ─── Mobile bottom sheet wrapper ──────────────────────────────────────────────

class _TaskFormSheet extends StatelessWidget {
  const _TaskFormSheet({this.task, this.defaultDate, this.defaultGoalId});

  final Task? task;
  final DateTime? defaultDate;
  final String? defaultGoalId;

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
            defaultGoalId: defaultGoalId,
            scrollController: controller,
          ),
        ),
      ),
    );
  }
}

// ─── Desktop dialog wrapper ───────────────────────────────────────────────────

class _TaskFormDialog extends StatelessWidget {
  const _TaskFormDialog({this.task, this.defaultDate, this.defaultGoalId});

  final Task? task;
  final DateTime? defaultDate;
  final String? defaultGoalId;

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
            child: _TaskFormContent(task: task, defaultDate: defaultDate, defaultGoalId: defaultGoalId),
          ),
        ),
      ),
    );
  }
}

// ─── Form content ─────────────────────────────────────────────────────────────

class _TaskFormContent extends ConsumerStatefulWidget {
  const _TaskFormContent({this.task, this.defaultDate, this.defaultGoalId, this.scrollController});

  final Task? task;
  final DateTime? defaultDate;
  final String? defaultGoalId;
  final ScrollController? scrollController;

  @override
  ConsumerState<_TaskFormContent> createState() => _TaskFormContentState();
}

class _TaskFormContentState extends ConsumerState<_TaskFormContent> {
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  final _titleFocusNode = FocusNode();
  final _noteFocusNode = FocusNode();
  final _bulletFormatter = const _BulletFormatter();

  late DateTime _selectedDate;
  late TaskPriority _priority;
  late TaskRecurrence _recurrence;
  late Set<int> _recurrenceDays;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String? _timeError;
  String? _selectedGoalId;

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
          !_setEquals(_recurrenceDays, Set<int>.from(t.recurrenceDays)) ||
          _toMinutes(_startTime) != t.startTimeMinutes ||
          _toMinutes(_endTime) != t.endTimeMinutes ||
          _selectedGoalId != t.goalId;
    }
    // Create mode: dirty if the user typed anything in the title
    return _titleController.text.trim().isNotEmpty;
  }

  int? _toMinutes(TimeOfDay? t) =>
      t != null ? t.hour * 60 + t.minute : null;

  String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
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
      _selectedGoalId = t.goalId;
      _startTime = t.startTimeMinutes != null
          ? TimeOfDay(
              hour: t.startTimeMinutes! ~/ 60,
              minute: t.startTimeMinutes! % 60)
          : null;
      _endTime = t.endTimeMinutes != null
          ? TimeOfDay(
              hour: t.endTimeMinutes! ~/ 60,
              minute: t.endTimeMinutes! % 60)
          : null;
    } else {
      // Defaults for create mode
      final now = DateTime.now();
      _selectedDate =
          widget.defaultDate ?? DateTime(now.year, now.month, now.day);
      _priority = TaskPriority.normal;
      _recurrence = TaskRecurrence.none;
      _recurrenceDays = {};
      _selectedGoalId = widget.defaultGoalId;
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
    _noteFocusNode.dispose();
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

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
      builder: _timePickerTheme,
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
        _timeError = null;
        // Auto-clear end time if it's now before start
        if (_endTime != null && _toMinutes(_endTime)! <= _toMinutes(picked)!) {
          _endTime = null;
        }
      });
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? _startTime ?? TimeOfDay.now(),
      builder: _timePickerTheme,
    );
    if (picked != null) {
      if (_startTime != null &&
          _toMinutes(picked)! <= _toMinutes(_startTime)!) {
        setState(() => _timeError = 'End time must be after start time');
        return;
      }
      setState(() {
        _endTime = picked;
        _timeError = null;
      });
    }
  }

  void _clearTime() => setState(() {
        _startTime = null;
        _endTime = null;
        _timeError = null;
      });

  Widget _timePickerTheme(BuildContext context, Widget? child) => Theme(
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
      );

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
              startTimeMinutes: _toMinutes(_startTime),
              endTimeMinutes: _toMinutes(_endTime),
              goalId: _selectedGoalId,
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
            startTimeMinutes: _toMinutes(_startTime),
            endTimeMinutes: _toMinutes(_endTime),
            goalId: _selectedGoalId,
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

        // Note field — primary after title
        const _FieldLabel('Notes'),
        const SizedBox(height: AppSpacing.xs),
        _inputContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notes toolbar
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.xs,
                  AppSpacing.sm,
                  0,
                ),
                child: Row(
                  children: [
                    Tooltip(
                      message: 'Add bullet point',
                      waitDuration: const Duration(milliseconds: 400),
                      child: Pressable(
                        onTap: () {
                          final ctrl = _noteController;
                          final text = ctrl.text;
                          final sel = ctrl.selection;
                          if (!sel.isValid) {
                            // Append bullet at end
                            final newText = text.isEmpty
                                ? '• '
                                : '$text\n• ';
                            ctrl.value = TextEditingValue(
                              text: newText,
                              selection: TextSelection.collapsed(
                                  offset: newText.length),
                            );
                          } else {
                            // Find line start
                            final pos = sel.baseOffset;
                            final lineStart =
                                text.lastIndexOf('\n', pos - 1) + 1;
                            final lineText = text.substring(lineStart,
                                text.indexOf('\n', lineStart) == -1
                                    ? text.length
                                    : text.indexOf('\n', lineStart));
                            if (lineText.startsWith('• ')) {
                              // Remove bullet from current line
                              final newText = text.substring(0, lineStart) +
                                  lineText.substring(2) +
                                  text.substring(lineStart + lineText.length);
                              ctrl.value = TextEditingValue(
                                text: newText,
                                selection: TextSelection.collapsed(
                                    offset: (pos - 2).clamp(lineStart, newText.length)),
                              );
                            } else {
                              // Add bullet to current line
                              final newText = '${text.substring(0, lineStart)}• ${text.substring(lineStart)}';
                              ctrl.value = TextEditingValue(
                                text: newText,
                                selection: TextSelection.collapsed(
                                    offset: pos + 2),
                              );
                            }
                          }
                          _noteFocusNode.requestFocus();
                        },
                        borderRadius: BorderRadius.circular(4),
                        hoverColor: AppColors.golden.withValues(alpha: 0.1),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm, vertical: 3),
                          child: Text(
                            '•—',
                            style: TextStyle(
                              fontFamily: AppTypography.bodyFont,
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.borderSubtle),
              TextField(
                controller: _noteController,
                focusNode: _noteFocusNode,
                style: _inputTextStyle,
                decoration: _inputDecoration('Add notes, context, or a plan...'),
                maxLines: null,
                minLines: 6,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                inputFormatters: [_bulletFormatter],
              ),
            ],
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
                vertical: AppSpacing.sm,
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

        // Time range field
        const _FieldLabel('Time'),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _startTime != null
                        ? AppColors.golden.withValues(alpha: 0.45)
                        : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    // Clock icon — shared, sits to the left of start
                    Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.md),
                      child: Icon(
                        Icons.schedule_outlined,
                        size: 15,
                        color: _startTime != null
                            ? AppColors.golden.withValues(alpha: 0.8)
                            : AppColors.textMuted,
                      ),
                    ),
                    // Start time tap target
                    Expanded(
                      child: Pressable(
                        onTap: _pickStartTime,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                        hoverColor: AppColors.golden.withValues(alpha: 0.06),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.sm,
                          ),
                          child: Text(
                            _startTime != null
                                ? _formatTime(_startTime!)
                                : 'Start',
                            style: TextStyle(
                              fontFamily: AppTypography.bodyFont,
                              fontSize: 13,
                              color: _startTime != null
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Arrow separator
                    Text(
                      '→',
                      style: TextStyle(
                        fontFamily: AppTypography.bodyFont,
                        fontSize: 12,
                        color: _startTime != null
                            ? AppColors.textMuted
                            : AppColors.border,
                      ),
                    ),
                    // End time tap target
                    Expanded(
                      child: Pressable(
                        onTap: _startTime != null ? _pickEndTime : null,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                        hoverColor: _startTime != null
                            ? AppColors.golden.withValues(alpha: 0.06)
                            : null,
                        child: Opacity(
                          opacity: _startTime != null ? 1.0 : 0.45,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.sm,
                            ),
                            child: Text(
                              _endTime != null
                                  ? _formatTime(_endTime!)
                                  : 'End',
                              style: TextStyle(
                                fontFamily: AppTypography.bodyFont,
                                fontSize: 13,
                                color: _endTime != null
                                    ? AppColors.textPrimary
                                    : AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Clear button (only when time is set)
            if (_startTime != null) ...[
              const SizedBox(width: AppSpacing.xs),
              Pressable(
                onTap: _clearTime,
                borderRadius: BorderRadius.circular(20),
                hoverColor: AppColors.error.withValues(alpha: 0.1),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.close, size: 16, color: AppColors.textMuted),
                ),
              ),
            ],
          ],
        ),
        if (_timeError != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            _timeError!,
            style: const TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: 12,
              color: AppColors.error,
            ),
          ),
        ],
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
        const SizedBox(height: AppSpacing.lg),

        // Goal field
        const _FieldLabel('Goal'),
        const SizedBox(height: AppSpacing.xs),
        _GoalPickerField(
          selectedGoalId: _selectedGoalId,
          onGoalSelected: (id) => setState(() => _selectedGoalId = id),
        ),

        const SizedBox(height: AppSpacing.xxxl),

        // Metadata (edit mode only)
        if (_isEditing) ...[
          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: AppSpacing.lg),
          _MetaRow(
            label: 'Created',
            value: DateFormat('MMM d, yyyy · h:mm a')
                .format(widget.task!.createdAt),
          ),
          if (widget.task!.completedAt != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _MetaRow(
              label: 'Completed',
              value: DateFormat('MMM d, yyyy · h:mm a')
                  .format(widget.task!.completedAt!),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
        ],

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

// ─── Goal picker field ────────────────────────────────────────────────────────

class _GoalPickerField extends ConsumerWidget {
  const _GoalPickerField({
    required this.selectedGoalId,
    required this.onGoalSelected,
  });

  final String? selectedGoalId;
  final ValueChanged<String?> onGoalSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(activeGoalsProvider);
    final goals = goalsAsync.valueOrNull ?? [];
    final selectedGoal = selectedGoalId != null
        ? goals.where((g) => g.id == selectedGoalId).firstOrNull
        : null;
    final gc = selectedGoal != null
        ? GoalColors.fromId(selectedGoal.color)
        : null;

    return Pressable(
      onTap: () async {
        final picked = await showDialog<String?>(
          context: context,
          builder: (_) => _GoalPickerDialog(
            goals: goals,
            selectedGoalId: selectedGoalId,
          ),
        );
        if (picked != null) {
          // picked == '' means "clear"
          onGoalSelected(picked.isEmpty ? null : picked);
        }
      },
      borderRadius: BorderRadius.circular(12),
      hoverColor: AppColors.golden.withValues(alpha: 0.06),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: gc != null ? gc.base.withValues(alpha: 0.6) : AppColors.border,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              if (gc != null) ...[
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: gc.base,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ] else ...[
                const Icon(Icons.flag_outlined,
                    size: 16, color: AppColors.textMuted),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Text(
                  selectedGoal?.title ?? 'No goal',
                  style: TextStyle(
                    fontFamily: AppTypography.bodyFont,
                    fontSize: 14,
                    color: selectedGoal != null
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                  ),
                ),
              ),
              if (selectedGoalId != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Pressable(
                  onTap: () => onGoalSelected(null),
                  borderRadius: BorderRadius.circular(20),
                  hoverColor: AppColors.error.withValues(alpha: 0.1),
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(Icons.close, size: 14, color: AppColors.textMuted),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalPickerDialog extends StatelessWidget {
  const _GoalPickerDialog({
    required this.goals,
    required this.selectedGoalId,
  });

  final List<Goal> goals;
  final String? selectedGoalId;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Link to Goal',
              style: TextStyle(
                fontFamily: AppTypography.displayFont,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (goals.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Text(
                  'No active goals.',
                  style: TextStyle(
                    fontFamily: AppTypography.bodyFont,
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    // No goal option
                    ListTile(
                      dense: true,
                      onTap: () => Navigator.of(context).pop(''),
                      leading: const Icon(Icons.remove_circle_outline,
                          size: 16, color: AppColors.textMuted),
                      title: const Text(
                        'No goal',
                        style: TextStyle(
                          fontFamily: AppTypography.bodyFont,
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                      trailing: selectedGoalId == null
                          ? const Icon(Icons.check,
                              size: 16, color: AppColors.golden)
                          : null,
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    for (final goal in goals) ...[
                      _GoalOption(
                        goal: goal,
                        isSelected: goal.id == selectedGoalId,
                        onTap: () => Navigator.of(context).pop(goal.id),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GoalOption extends StatelessWidget {
  const _GoalOption({
    required this.goal,
    required this.isSelected,
    required this.onTap,
  });

  final Goal goal;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final gc = GoalColors.fromId(goal.color);
    return ListTile(
      dense: true,
      onTap: onTap,
      leading: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: gc.base,
          shape: BoxShape.circle,
        ),
      ),
      title: Text(
        goal.title,
        style: const TextStyle(
          fontFamily: AppTypography.bodyFont,
          fontSize: 13,
          color: AppColors.textPrimary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: isSelected
          ? const Icon(Icons.check, size: 16, color: AppColors.golden)
          : null,
    );
  }
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

// ─── Metadata row ─────────────────────────────────────────────────────────────

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            fontFamily: AppTypography.bodyFont,
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          value,
          style: const TextStyle(
            fontFamily: AppTypography.bodyFont,
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ─── Bullet formatter ─────────────────────────────────────────────────────────

/// Auto-continues bullet points when the user presses Enter on a bullet line.
/// Pressing Enter on an empty bullet line (just '• ') removes the bullet.
class _BulletFormatter extends TextInputFormatter {
  const _BulletFormatter();

  static const _bullet = '• ';

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Only react when exactly one character was inserted.
    if (newValue.text.length != oldValue.text.length + 1) return newValue;

    final pos = newValue.selection.baseOffset;
    if (pos <= 0) return newValue;

    final inserted = newValue.text[pos - 1];
    if (inserted != '\n') return newValue;

    // Find the line that was just completed (the one before the newline).
    final prevLineStart = newValue.text.lastIndexOf('\n', pos - 2) + 1;
    final prevLine = newValue.text.substring(prevLineStart, pos - 1);

    if (prevLine == _bullet.trimRight() || prevLine == _bullet) {
      // Empty bullet line — remove it and stop bullet mode.
      final newText =
          newValue.text.substring(0, prevLineStart) + newValue.text.substring(pos);
      return TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: prevLineStart),
      );
    }

    if (prevLine.startsWith(_bullet)) {
      // Continue bullet on new line.
      final newText =
          newValue.text.substring(0, pos) + _bullet + newValue.text.substring(pos);
      return TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: pos + _bullet.length),
      );
    }

    return newValue;
  }
}
