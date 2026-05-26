import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

/// Sets the test surface to 360x800 dp at 1:1 pixel ratio.
///
/// Use for widget tests that must catch phone-width layout regressions.
void set360dpSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
