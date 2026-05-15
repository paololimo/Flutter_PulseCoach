import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';

class CompletionRing extends StatelessWidget {
  final int completed;
  final int total;

  const CompletionRing({
    super.key,
    required this.completed,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final pulseThemeOrNull = Theme.of(context).extension<PulseCoachTheme>();
    assert(
      pulseThemeOrNull != null,
      'CompletionRing requires PulseCoachTheme extension',
    );
    final pulseTheme = pulseThemeOrNull!;

    return Semantics(
      label:
          'Progressione giornaliera: $completed di $total sessioni completate',
      child: SizedBox(
        width: 48,
        height: 48,
        child: CustomPaint(
          painter: _RingPainter(
            completed: completed,
            total: total,
            trackColor: pulseTheme.onSurfaceVariant.withValues(alpha: 0.2),
            progressColor: pulseTheme.primaryColor,
          ),
          child: Center(
            child: Text(
              '$completed/$total',
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final int completed;
  final int total;
  final Color trackColor;
  final Color progressColor;

  const _RingPainter({
    required this.completed,
    required this.total,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 4) / 2;
    const startAngle = -math.pi / 2;

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    canvas.drawCircle(center, radius, trackPaint);

    if (total > 0 && completed > 0) {
      final sweepAngle = 2 * math.pi * (completed / total).clamp(0, 1);
      final progressPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = progressColor;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.completed != completed || oldDelegate.total != total;
}
