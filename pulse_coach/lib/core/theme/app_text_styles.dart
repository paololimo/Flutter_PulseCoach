import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class AppTextStyles {
  // JetBrains Mono — data/metrics only
  static TextStyle get timerDisplay =>
      GoogleFonts.jetBrainsMono(fontSize: 48, height: 1.0);
  static TextStyle get countdown =>
      GoogleFonts.jetBrainsMono(fontSize: 72, height: 1.0);
  static TextStyle get rpeNumbers =>
      GoogleFonts.jetBrainsMono(fontSize: 20, height: 1.0);
  static TextStyle get timerSecondary =>
      GoogleFonts.jetBrainsMono(fontSize: 24, height: 1.0);

  // Plus Jakarta Sans — all body/UI text
  static TextStyle get display => GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        height: 1.2,
      );
  static TextStyle get h1 => GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.25,
      );
  static TextStyle get h2 => GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );
  static TextStyle get h3 => GoogleFonts.plusJakartaSans(
        fontSize: 17,
        fontWeight: FontWeight.w500,
        height: 1.35,
      );
  static TextStyle get body => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );
  static TextStyle get bodySmall => GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.45,
      );
  // NOTE: 11sp is the absolute minimum — never use a smaller size anywhere in the app
  static TextStyle get caption => GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        height: 1.4,
      );
}
