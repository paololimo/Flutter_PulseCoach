import 'package:flutter/material.dart';

abstract class AppTextStyles {
  static const _bodyFontFamily = 'Plus Jakarta Sans';
  static const _monoFontFamily = 'JetBrains Mono';

  // JetBrains Mono — data/metrics only
  static const TextStyle timerDisplay = TextStyle(
    fontFamily: _monoFontFamily,
    fontSize: 48,
    height: 1.0,
  );
  static const TextStyle countdown = TextStyle(
    fontFamily: _monoFontFamily,
    fontSize: 72,
    height: 1.0,
  );
  static const TextStyle rpeNumbers = TextStyle(
    fontFamily: _monoFontFamily,
    fontSize: 20,
    height: 1.0,
  );
  static const TextStyle timerSecondary = TextStyle(
    fontFamily: _monoFontFamily,
    fontSize: 24,
    height: 1.0,
  );

  // Plus Jakarta Sans — all body/UI text
  static const TextStyle display = TextStyle(
    fontFamily: _bodyFontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
  static const TextStyle h1 = TextStyle(
    fontFamily: _bodyFontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );
  static const TextStyle h2 = TextStyle(
    fontFamily: _bodyFontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
  static const TextStyle h3 = TextStyle(
    fontFamily: _bodyFontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w500,
    height: 1.35,
  );
  static const TextStyle body = TextStyle(
    fontFamily: _bodyFontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  static const TextStyle bodySmall = TextStyle(
    fontFamily: _bodyFontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );
  // NOTE: 11sp is the absolute minimum — never use a smaller size anywhere in the app
  static const TextStyle caption = TextStyle(
    fontFamily: _bodyFontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );
}
