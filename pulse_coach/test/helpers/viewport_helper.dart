import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

/// Sets the test surface to 360x800 dp at 1:1 pixel ratio.
///
/// Use for widget tests that must catch phone-width layout regressions.
void set360dpSurface(WidgetTester tester) {
  setPhoneSurface(tester, size: const Size(360, 800));
}

/// Sets the test surface to 360x640 dp at 1:1 pixel ratio — a compact phone
/// device profile (the smallest common Android viewport we target).
///
/// Use for widget tests that must reproduce short-viewport layout — the class
/// of real-viewport regression that isolated widget tests miss because the
/// default 800x600 test surface is both wider and taller than a real phone
/// (e.g. the Epic 22 FactorIconRow vertical-stack, E22R-1).
void set360x640Surface(WidgetTester tester) {
  setPhoneSurface(tester, size: const Size(360, 640));
}

/// Sets the test surface to [size] dp at 1:1 pixel ratio and restores it on
/// tear-down. Prefer the named [set360dpSurface] / [set360x640Surface]
/// device profiles; use this directly only for a one-off viewport.
void setPhoneSurface(WidgetTester tester, {required Size size}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
