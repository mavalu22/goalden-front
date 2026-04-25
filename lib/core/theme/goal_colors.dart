import 'package:flutter/material.dart';

/// A single goal color with three tonal variants.
///
/// - [base] — the full-strength color used for borders, icons, and accents.
/// - [dim]  — ~22% alpha overlay; used for tinted card backgrounds.
/// - [soft] — ~8% alpha overlay; used for very subtle background washes.
///
/// All three variants pass contrast requirements against the app's dark
/// background (#141414) for body text rendered on [dim] and [soft] layers.
class GoalColor {
  const GoalColor({
    required this.id,
    required this.base,
    required this.dim,
    required this.soft,
  });

  final String id;
  final Color base;
  final Color dim;
  final Color soft;
}

/// The fixed palette of goal colors, harmonized with the dark theme and the
/// golden accent (#D4AF37).  Every goal is assigned one entry from this list.
abstract class GoalColors {
  static const coral = GoalColor(
    id: 'coral',
    base: Color(0xFFE07070),
    dim: Color(0x38E07070),
    soft: Color(0x14E07070),
  );

  static const sage = GoalColor(
    id: 'sage',
    base: Color(0xFF72B07A),
    dim: Color(0x3872B07A),
    soft: Color(0x1472B07A),
  );

  static const sky = GoalColor(
    id: 'sky',
    base: Color(0xFF5B9BD5),
    dim: Color(0x385B9BD5),
    soft: Color(0x145B9BD5),
  );

  static const lavender = GoalColor(
    id: 'lavender',
    base: Color(0xFF9B7FC0),
    dim: Color(0x389B7FC0),
    soft: Color(0x149B7FC0),
  );

  static const marigold = GoalColor(
    id: 'marigold',
    base: Color(0xFFD4A030),
    dim: Color(0x38D4A030),
    soft: Color(0x14D4A030),
  );

  static const teal = GoalColor(
    id: 'teal',
    base: Color(0xFF4AABA0),
    dim: Color(0x384AABA0),
    soft: Color(0x144AABA0),
  );

  static const rose = GoalColor(
    id: 'rose',
    base: Color(0xFFD06A8A),
    dim: Color(0x38D06A8A),
    soft: Color(0x14D06A8A),
  );

  static const slate = GoalColor(
    id: 'slate',
    base: Color(0xFF7A96A8),
    dim: Color(0x387A96A8),
    soft: Color(0x147A96A8),
  );

  /// The full ordered palette.  Colors cycle in this order when
  /// auto-assigning to new goals.
  static const List<GoalColor> palette = [
    coral,
    sage,
    sky,
    lavender,
    marigold,
    teal,
    rose,
    slate,
  ];

  /// Look up a [GoalColor] by its [id] string.
  /// Falls back to [coral] for unknown ids.
  static GoalColor fromId(String id) {
    return palette.firstWhere(
      (c) => c.id == id,
      orElse: () => coral,
    );
  }

  /// Suggest the next color in the palette given the count of existing goals.
  /// Cycles through the palette when the count exceeds palette length.
  static GoalColor suggest(int existingGoalCount) {
    return palette[existingGoalCount % palette.length];
  }
}
