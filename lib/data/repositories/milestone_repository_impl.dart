import 'package:drift/drift.dart';

import '../../domain/models/milestone.dart';
import '../../domain/repositories/milestone_repository.dart';
import '../local/daos/milestone_dao.dart';
import '../local/database.dart';

class MilestoneRepositoryImpl implements MilestoneRepository {
  MilestoneRepositoryImpl(this._dao);

  final MilestoneDao _dao;

  @override
  Stream<List<Milestone>> watchMilestonesForGoal(String goalId) =>
      _dao.watchMilestonesForGoal(goalId).map(
            (entries) => entries.map(_fromEntry).toList(),
          );

  @override
  Future<List<Milestone>> getMilestonesForGoal(String goalId) async {
    final entries = await _dao.getMilestonesForGoal(goalId);
    return entries.map(_fromEntry).toList();
  }

  @override
  Future<void> createMilestone(Milestone milestone) {
    final now = DateTime.now().toUtc();
    return _dao.insertMilestone(
      _toCompanion(milestone).copyWith(
        updatedAt: Value(now),
        syncStatus: const Value('pending_create'),
      ),
    );
  }

  @override
  Future<void> updateMilestone(Milestone milestone) {
    final now = DateTime.now().toUtc();
    return _dao.updateMilestone(
      _toCompanion(milestone).copyWith(
        updatedAt: Value(now),
        syncStatus: const Value('pending_update'),
      ),
    );
  }

  @override
  Future<void> completeMilestone(String id, {required bool done}) async {
    final existing = await _dao.getMilestoneById(id);
    if (existing == null) return;
    final now = DateTime.now().toUtc();
    await _dao.updateMilestone(
      MilestonesCompanion(
        id: Value(id),
        goalId: Value(existing.goalId),
        userId: Value(existing.userId),
        title: Value(existing.title),
        date: Value(existing.date),
        done: Value(done),
        completedAt: Value(done ? now : null),
        createdAt: Value(existing.createdAt),
        updatedAt: Value(now),
        syncStatus: const Value('pending_update'),
      ),
    );
  }

  @override
  Future<void> deleteMilestone(String id) => _dao.softDeleteMilestone(id);

  @override
  Future<void> deleteMilestonesForGoal(String goalId) =>
      _dao.softDeleteMilestonesForGoal(goalId);

  // ─── Mapping ──────────────────────────────────────────────────────────────

  Milestone _fromEntry(MilestoneEntry e) {
    return Milestone(
      id: e.id,
      goalId: e.goalId,
      userId: e.userId,
      title: e.title,
      date: e.date,
      done: e.done,
      completedAt: e.completedAt,
      createdAt: e.createdAt,
      updatedAt: e.updatedAt,
    );
  }

  MilestonesCompanion _toCompanion(Milestone m) {
    final effectiveUpdatedAt = m.updatedAt ?? m.createdAt;
    return MilestonesCompanion(
      id: Value(m.id),
      goalId: Value(m.goalId),
      userId: Value(m.userId),
      title: Value(m.title),
      date: Value(m.date),
      done: Value(m.done),
      completedAt: Value(m.completedAt),
      createdAt: Value(m.createdAt),
      updatedAt: Value(effectiveUpdatedAt),
    );
  }
}
