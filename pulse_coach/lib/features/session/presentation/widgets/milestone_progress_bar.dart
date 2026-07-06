import 'package:flutter/material.dart';
import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

class MilestoneProgressBar extends StatefulWidget {
  final int currentStepIndex;
  final int totalSteps;
  final bool isComplete;

  const MilestoneProgressBar({
    required this.currentStepIndex,
    required this.totalSteps,
    required this.isComplete,
    super.key,
  });

  @override
  State<MilestoneProgressBar> createState() => _MilestoneProgressBarState();
}

class _MilestoneProgressBarState extends State<MilestoneProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _settleController;
  late Animation<double> _settleAnimation;

  @override
  void initState() {
    super.initState();
    _settleController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _settleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _settleController, curve: Curves.easeOut),
    );
    if (widget.isComplete) {
      _settleController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(MilestoneProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isComplete && widget.isComplete) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _settleController.value = 1.0;
      } else {
        _settleController.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _settleController.dispose();
    super.dispose();
  }

  static double _progressOf(int currentStepIndex, int totalSteps) {
    if (totalSteps <= 0) return 0.0;
    return ((currentStepIndex + 1) / totalSteps).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final pulseTheme = Theme.of(context).extension<PulseCoachTheme>()!;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final l10n = AppLocalizations.of(context)!;
    final progress = _progressOf(widget.currentStepIndex, widget.totalSteps);
    final currentLabel = (widget.currentStepIndex + 1).toString();
    final totalLabel = widget.totalSteps.toString();
    final label = widget.isComplete
        ? l10n.milestoneProgressBarReachedLabel(currentLabel, totalLabel)
        : l10n.milestoneProgressBarUnreachedLabel(currentLabel, totalLabel);

    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: SizedBox(
          height: 24,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.hasBoundedWidth
                  ? constraints.maxWidth
                  : 300.0;
              return AnimatedBuilder(
                animation: _settleController,
                builder: (context, _) {
                  return CustomPaint(
                    size: Size(width, 24),
                    painter: _MilestonePainter(
                      progress: progress,
                      totalSteps: widget.totalSteps,
                      primaryColor: pulseTheme.primaryColor,
                      railColor: pulseTheme.onSurfaceVariant.withValues(
                        alpha: 0.2,
                      ),
                      notchColor: pulseTheme.onSurfaceVariant,
                      isComplete: widget.isComplete,
                      onPrimaryColor: onPrimary,
                      settleValue: _settleAnimation.value,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MilestonePainter extends CustomPainter {
  static const double _trackHeight = 4;
  static const double _notchGap = 2;
  static const double _finishMarkerRadius = 8;

  // Reused across paint() calls so the settle animation repaints allocate no
  // Paint objects per frame (AC6 — no per-frame allocations). Color is set at
  // paint time; the invariant stroke properties are set once here.
  static final Paint _railPaint = Paint();
  static final Paint _fillPaint = Paint();
  static final Paint _notchPaint = Paint()..strokeWidth = 1.5;
  static final Paint _markerFillPaint = Paint();
  static final Paint _glyphPaint = Paint();
  static final Paint _outlinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  final double progress;
  final int totalSteps;
  final Color primaryColor;
  final Color railColor;
  final Color notchColor;
  final bool isComplete;
  final Color onPrimaryColor;
  final double settleValue;

  const _MilestonePainter({
    required this.progress,
    required this.totalSteps,
    required this.primaryColor,
    required this.railColor,
    required this.notchColor,
    required this.isComplete,
    required this.onPrimaryColor,
    required this.settleValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final trackWidth = size.width - _finishMarkerRadius * 2;
    final centerY = size.height / 2;
    _railPaint.color = railColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, centerY - _trackHeight / 2, trackWidth, _trackHeight),
        const Radius.circular(_trackHeight / 2),
      ),
      _railPaint,
    );

    final fillWidth = progress * trackWidth;
    if (fillWidth > 0) {
      _fillPaint.color = primaryColor;
      var start = 0.0;
      if (totalSteps > 1) {
        for (var i = 1; i < totalSteps; i++) {
          // Same operation order as fillWidth (`progress * trackWidth`) so the
          // boundary at i == currentStepIndex + 1 compares exactly equal to the
          // fill edge instead of differing by a floating-point ULP.
          final x = i / totalSteps * trackWidth;
          if (x >= fillWidth) break;
          final segmentEnd = (x - _notchGap / 2).clamp(start, fillWidth);
          if (segmentEnd > start) {
            _drawFillSegment(canvas, _fillPaint, start, segmentEnd, centerY);
          }
          start = (x + _notchGap / 2).clamp(start, fillWidth);
        }
      }
      if (fillWidth > start) {
        _drawFillSegment(canvas, _fillPaint, start, fillWidth, centerY);
      }
    }

    if (totalSteps > 1) {
      _notchPaint.color = notchColor;
      for (var i = 1; i < totalSteps; i++) {
        final x = i / totalSteps * trackWidth;
        if (x >= fillWidth) {
          canvas.drawLine(
            Offset(x, centerY - _trackHeight),
            Offset(x, centerY + _trackHeight),
            _notchPaint,
          );
        }
      }
    }

    final markerCenter = Offset(trackWidth + _finishMarkerRadius, centerY);
    if (isComplete) {
      final scale = 0.7 + 0.3 * settleValue;
      _markerFillPaint.color = primaryColor;
      canvas.drawCircle(
        markerCenter,
        _finishMarkerRadius * scale,
        _markerFillPaint,
      );
      _glyphPaint.color = onPrimaryColor;
      canvas.drawCircle(
        markerCenter,
        _finishMarkerRadius * scale * 0.4,
        _glyphPaint,
      );
    } else {
      _outlinePaint.color = notchColor;
      canvas.drawCircle(markerCenter, _finishMarkerRadius, _outlinePaint);
    }
  }

  void _drawFillSegment(
    Canvas canvas,
    Paint paint,
    double startX,
    double endX,
    double centerY,
  ) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(startX, centerY - _trackHeight / 2, endX - startX, _trackHeight),
        const Radius.circular(_trackHeight / 2),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_MilestonePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.totalSteps != totalSteps ||
      oldDelegate.primaryColor != primaryColor ||
      oldDelegate.railColor != railColor ||
      oldDelegate.notchColor != notchColor ||
      oldDelegate.isComplete != isComplete ||
      oldDelegate.onPrimaryColor != onPrimaryColor ||
      oldDelegate.settleValue != settleValue;
}
