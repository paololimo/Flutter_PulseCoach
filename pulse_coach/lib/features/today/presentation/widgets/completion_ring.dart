import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';

class CompletionRing extends StatefulWidget {
  final int completed;
  final int total;

  const CompletionRing({
    super.key,
    required this.completed,
    required this.total,
  });

  @override
  State<CompletionRing> createState() => _CompletionRingState();
}

class _CompletionRingState extends State<CompletionRing>
    with TickerProviderStateMixin {
  late AnimationController _arcController;
  late AnimationController _pulseController;
  late Animation<double> _arcAnimation;
  late Animation<double> _pulseAnimation;
  int _transitionId = 0;

  static double _progressOf(int completed, int total) {
    if (total <= 0) return 0.0;
    return completed.clamp(0, total) / total;
  }

  static bool _isCompletedOf(int completed, int total) =>
      total > 0 && completed >= total;

  @override
  void initState() {
    super.initState();
    _arcController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _arcAnimation = AlwaysStoppedAnimation<double>(
      _progressOf(widget.completed, widget.total),
    );
    _pulseAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.08), weight: 50),
          TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 50),
        ]).animate(
          CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
        );
  }

  @override
  void didUpdateWidget(CompletionRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.completed == widget.completed &&
        oldWidget.total == widget.total) {
      return;
    }

    final wasCompleted = _isCompletedOf(oldWidget.completed, oldWidget.total);
    final isCompleted = _isCompletedOf(widget.completed, widget.total);
    final newProgress = _progressOf(widget.completed, widget.total);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    // Invalidate any in-flight transition so a stale TickerFuture cannot fire
    // a pulse or otherwise apply state from a superseded animation.
    final transitionId = ++_transitionId;
    // Begin the next tween from the current displayed value so rapid updates
    // don't snap back to a stale baseline.
    final currentValue = _arcAnimation.value.clamp(0.0, 1.0);

    if (disableAnimations) {
      _arcController.stop();
      _pulseController.reset();
      _arcAnimation = AlwaysStoppedAnimation<double>(newProgress);
    } else {
      _arcAnimation = Tween<double>(begin: currentValue, end: newProgress)
          .animate(
            CurvedAnimation(parent: _arcController, curve: Curves.easeInOut),
          );
      _arcController.forward(from: 0).then((_) {
        if (!mounted || transitionId != _transitionId) {
          return;
        }
        // Pulse only on the first crossing into the fully-completed state.
        if (!wasCompleted && isCompleted) {
          _pulseController.forward(from: 0);
        }
      });
    }
  }

  @override
  void dispose() {
    _arcController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pulseThemeOrNull = Theme.of(context).extension<PulseCoachTheme>();
    assert(
      pulseThemeOrNull != null,
      'CompletionRing requires PulseCoachTheme extension',
    );
    final pulseTheme = pulseThemeOrNull!;

    return AnimatedBuilder(
      animation: Listenable.merge([_arcController, _pulseController]),
      builder: (context, _) {
        return Semantics(
          label:
              'Progressione giornaliera: ${widget.completed} di '
              '${widget.total} sessioni completate',
          child: Transform.scale(
            scale: _pulseAnimation.value,
            child: SizedBox(
              width: 48,
              height: 48,
              child: CustomPaint(
                painter: _RingPainter(
                  progress: _arcAnimation.value.clamp(0.0, 1.0),
                  trackColor: pulseTheme.onSurfaceVariant.withValues(
                    alpha: 0.2,
                  ),
                  progressColor: pulseTheme.primaryColor,
                ),
                child: Center(
                  child: Text(
                    '${widget.completed}/${widget.total}',
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;

  const _RingPainter({
    required this.progress,
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

    if (progress > 0) {
      final sweepAngle = 2 * math.pi * progress;
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
      oldDelegate.progress != progress;
}
