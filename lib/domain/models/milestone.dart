import 'package:freezed_annotation/freezed_annotation.dart';

part 'milestone.freezed.dart';

@freezed
abstract class Milestone with _$Milestone {
  const factory Milestone({
    required String id,
    required String goalId,
    required String userId,
    required String title,
    required DateTime date,
    @Default(false) bool done,
    DateTime? completedAt,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _Milestone;
}
