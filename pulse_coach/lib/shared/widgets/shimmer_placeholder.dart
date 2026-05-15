import 'package:flutter/material.dart';
import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerPlaceholder extends StatelessWidget {
  final double height;
  final double? width;
  final double borderRadius;

  const ShimmerPlaceholder({
    super.key,
    required this.height,
    this.width,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final pulseThemeOrNull = Theme.of(context).extension<PulseCoachTheme>();
    assert(
      pulseThemeOrNull != null,
      'ShimmerPlaceholder requires PulseCoachTheme extension',
    );
    final pulseTheme = pulseThemeOrNull!;

    return Shimmer.fromColors(
      baseColor: pulseTheme.surfaceContainer,
      highlightColor: pulseTheme.onSurfaceVariant.withValues(alpha: 0.1),
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: pulseTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
