import 'package:flutter/material.dart';

/// UX-DR23 medal accent colors — fixed hex values (not theme-dependent),
/// same convention as sessionAccentColor's cardio literal
/// (session_card_helpers.dart). Returns null for rank > 3 (no medal).
Color? medalColor(int rank) => switch (rank) {
  1 => const Color(0xFFE8C87A), // gold
  2 => const Color(0xFF9498A6), // silver
  3 => const Color(0xFFF0A1B0), // bronze
  _ => null,
};

/// Shape-distinct glyph per medal (never rely on color alone, UX-DR23/33).
IconData? medalIcon(int rank) => switch (rank) {
  1 => Icons.star,
  2 => Icons.hexagon,
  3 => Icons.diamond,
  _ => null,
};
