import 'package:drift/drift.dart';

import '../../domain/models/goal.dart';
import '../../domain/repositories/goal_repository.dart';
import '../local/daos/goal_dao.dart';
import '../local/database.dart';

class GoalRepositoryImpl implements GoalRepository {
  GoalRepositoryImpl(this._dao);

  final GoalDao _dao;

  @override
  Stream<List<Goal>> watchActiveGoals() =>
      _dao.watchActiveGoals().map((entries) => entries.map(_fromEntry).toList());

  @override
  Stream<List<Goal>> watchArchivedGoals() =>
      _dao.watchArchivedGoals().map(
        (entries) => entries.map(_fromEntry).toList(),
      );

  @override
  Future<List<Goal>> getAllGoals() async {
    final entries = await _dao.getAllGoals();
    return entries.map(_fromEntry).toList();
  }

  @override
  Future<Goal?> getGoalById(String id) async {
    final entry = await _dao.getGoalById(id);
    return entry != null ? _fromEntry(entry) : null;
  }

  @override
  Stream<Goal?> watchGoalById(String id) =>
      _dao.watchGoalById(id).map((e) => e != null ? _fromEntry(e) : null);

  @override
  Future<void> createGoal(Goal goal) {
    final now = DateTime.now().toUtc();
    return _dao.insertGoal(
      _toCompanion(goal).copyWith(
        updatedAt: Value(now),
        syncStatus: const Value('pending_create'),
      ),
    );
  }

  @override
  Future<void> updateGoal(Goal goal) {
    final now = DateTime.now().toUtc();
    return _dao.updateGoal(
      _toCompanion(goal).copyWith(
        updatedAt: Value(now),
        syncStatus: const Value('pending_update'),
      ),
    );
  }

  @override
  Future<void> archiveGoal(String id) => _dao.archiveGoal(id);

  @override
  Future<void> unarchiveGoal(String id) => _dao.unarchiveGoal(id);

  @override
  Future<void> deleteGoal(String id) => _dao.softDeleteGoal(id);

  // ─── Mapping ──────────────────────────────────────────────────────────────

  Goal _fromEntry(GoalEntry e) {
    return Goal(
      id: e.id,
      userId: e.userId,
      title: e.title,
      description: e.description,
      color: e.color,
      status: e.status == 'archived' ? GoalStatus.archived : GoalStatus.active,
      deadline: e.deadline,
      starred: e.starred,
      createdAt: e.createdAt,
      updatedAt: e.updatedAt,
      archivedAt: e.archivedAt,
    );
  }

  GoalsCompanion _toCompanion(Goal g) {
    final effectiveUpdatedAt = g.updatedAt ?? g.createdAt;
    return GoalsCompanion(
      id: Value(g.id),
      userId: Value(g.userId),
      title: Value(g.title),
      description: Value(g.description),
      color: Value(g.color),
      status: Value(g.status == GoalStatus.archived ? 'archived' : 'active'),
      deadline: Value(g.deadline),
      starred: Value(g.starred),
      createdAt: Value(g.createdAt),
      updatedAt: Value(effectiveUpdatedAt),
      archivedAt: Value(g.archivedAt),
    );
  }
}
