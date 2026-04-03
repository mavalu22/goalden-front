import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/models/task.dart';
import '../providers/today_provider.dart';

const _messages = [
  'New day, fresh start ✨',
  "Yesterday's tasks are waiting 💪",
  'Clean the slate, one task at a time 🧹',
  'Carry forward, finish strong 🏁',
  "These tasks didn't forget you 👀",
];

/// Seeded motivational message — one per session, stable across rebuilds.
final _pendingMessageProvider = StateProvider<String>((ref) {
  return _messages[Random().nextInt(_messages.length)];
});

class PendingSection extends ConsumerWidget {
  const PendingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingTasksProvider);

    return pendingAsync.when(
      data: (tasks) {
        if (tasks.isEmpty) return const SizedBox.shrink();
        final message = ref.watch(_pendingMessageProvider);
        return _PendingSectionContent(tasks: tasks, message: message);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _PendingSectionContent extends StatelessWidget {
  const _PendingSectionContent({
    required this.tasks,
    required this.message,
  });

  final List<Task> tasks;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.goldenDim,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.goldenBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: AppTypography.bodyFont,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.golden,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const Divider(
            height: 1,
            thickness: 1,
            color: AppColors.goldenBorder,
          ),
          ...tasks.map((task) => _PendingTaskRow(task: task)),
        ],
      ),
    );
  }
}

class _PendingTaskRow extends ConsumerWidget {
  const _PendingTaskRow({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          // Golden-bordered checkbox
          GestureDetector(
            onTap: () =>
                ref.read(taskActionsProvider.notifier).toggleDone(task),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                border: Border.all(
                  color: AppColors.golden,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Task title
          Expanded(
            child: Text(
              task.title,
              style: const TextStyle(
                fontFamily: AppTypography.bodyFont,
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // "Today" pill button
          GestureDetector(
            onTap: () =>
                ref.read(taskActionsProvider.notifier).rescheduleToToday(task),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: AppColors.goldenDim,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.goldenBorder),
              ),
              child: const Text(
                'Today',
                style: TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.golden,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Remove button
          GestureDetector(
            onTap: () =>
                ref.read(taskActionsProvider.notifier).deleteTask(task.id),
            child: const Icon(
              Icons.close,
              size: 16,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
