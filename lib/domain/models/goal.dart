import 'package:freezed_annotation/freezed_annotation.dart';

part 'goal.freezed.dart';

enum GoalStatus { active, archived }

@freezed
abstract class Goal with _$Goal {
  const factory Goal({
    required String id,
    required String userId,
    required String title,
    String? description,
    required String color,
    @Default(GoalStatus.active) GoalStatus status,
    DateTime? deadline,
    @Default(false) bool starred,
    required DateTime createdAt,
    DateTime? updatedAt,
    DateTime? archivedAt,
  }) = _Goal;
}
