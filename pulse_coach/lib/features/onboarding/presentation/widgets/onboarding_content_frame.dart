import 'package:flutter/material.dart';

/// Centres onboarding content and caps its width on large screens so the
/// profile form's controls don't stretch edge to edge on tablets.
///
/// Below [breakpoint] (phones, tablet portrait, the default test surface) it is
/// a transparent pass-through — the child is returned untouched, so narrow
/// layouts keep their exact behaviour. At or above [breakpoint] the child is
/// centred and capped to [maxWidth].
///
/// Intended for use inside a [SingleChildScrollView]: [Center] shrink-wraps its
/// height when the incoming vertical constraint is unbounded, so the content
/// keeps its natural height and scrolls rather than overflowing.
class OnboardingContentFrame extends StatelessWidget {
  const OnboardingContentFrame({
    super.key,
    required this.child,
    this.maxWidth = 640,
    this.breakpoint = 840,
  });

  final Widget child;
  final double maxWidth;
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return child;
        }
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        );
      },
    );
  }
}
