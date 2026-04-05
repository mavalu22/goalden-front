import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/models/task.dart';

/// Result of the delete confirmation dialog.
enum DeleteResult {
  /// Delete only this instance; future recurrences continue.
  thisInstance,

  /// Delete the source and all future instances.
  allFuture,

  /// User cancelled — do not delete.
  cancelled,
}

/// Shows a styled delete confirmation dialog appropriate for the task type.
///
/// For non-recurring tasks returns [DeleteResult.thisInstance] on confirm
/// or [DeleteResult.cancelled] on dismiss.
///
/// For recurring tasks returns [DeleteResult.thisInstance],
/// [DeleteResult.allFuture], or [DeleteResult.cancelled].
Future<DeleteResult> showDeleteConfirmation(
  BuildContext context,
  Task task,
) {
  final isRecurring = task.sourceTaskId != null ||
      task.recurrence != TaskRecurrence.none;

  return showDialog<DeleteResult>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (ctx) => _DeleteDialog(isRecurring: isRecurring),
  ).then((result) => result ?? DeleteResult.cancelled);
}

class _DeleteDialog extends StatelessWidget {
  const _DeleteDialog({required this.isRecurring});

  final bool isRecurring;

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
              'Delete task',
              style: TextStyle(
                fontFamily: AppTypography.displayFont,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isRecurring
                  ? 'This is a recurring task. How would you like to delete it?'
                  : 'Are you sure you want to delete this task? This cannot be undone.',
              style: const TextStyle(
                fontFamily: AppTypography.bodyFont,
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (isRecurring) ...[
              _ActionButton(
                label: 'Delete this instance',
                subtitle: 'Future recurrences will continue',
                onTap: () =>
                    Navigator.of(context).pop(DeleteResult.thisInstance),
                color: AppColors.error,
              ),
              const SizedBox(height: AppSpacing.sm),
              _ActionButton(
                label: 'Delete all future instances',
                subtitle: 'Removes the series and all upcoming occurrences',
                onTap: () => Navigator.of(context).pop(DeleteResult.allFuture),
                color: AppColors.error,
              ),
              const SizedBox(height: AppSpacing.md),
              _CancelButton(
                  onTap: () =>
                      Navigator.of(context).pop(DeleteResult.cancelled)),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: _CancelButton(
                      onTap: () =>
                          Navigator.of(context).pop(DeleteResult.cancelled),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          Navigator.of(context).pop(DeleteResult.thisInstance),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md),
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
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.subtitle,
    required this.onTap,
    required this.color,
  });

  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CancelButton extends StatelessWidget {
  const _CancelButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      ),
      child: const Text(
        'Cancel',
        style: TextStyle(
          fontFamily: AppTypography.bodyFont,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
