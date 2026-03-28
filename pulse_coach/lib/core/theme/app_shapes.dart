import 'package:flutter/material.dart';

abstract class AppShapes {
  static const double cardRadius = 16.0;
  static const double buttonRadius = 12.0;
  static const double inputRadius = 8.0;

  static const cardBorderRadius =
      BorderRadius.all(Radius.circular(cardRadius));
  static const buttonBorderRadius =
      BorderRadius.all(Radius.circular(buttonRadius));
  static const inputBorderRadius =
      BorderRadius.all(Radius.circular(inputRadius));
}
