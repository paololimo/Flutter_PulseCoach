import 'package:flutter/material.dart';
import 'package:pulse_coach/core/theme/app_text_styles.dart';
import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

class CountdownOverlay extends StatefulWidget {
  final String? sessionTitle;
  final VoidCallback onCountdownComplete;

  const CountdownOverlay({
    required this.onCountdownComplete,
    this.sessionTitle,
    super.key,
  });

  @override
  State<CountdownOverlay> createState() => _CountdownOverlayState();
}

class _CountdownOverlayState extends State<CountdownOverlay>
    with SingleTickerProviderStateMixin {
  static const _ritualDuration = Duration(milliseconds: 400);
  static const _holdDuration = Duration(milliseconds: 700);
  static const _goDuration = Duration(milliseconds: 300);

  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;
  int _count = 3;
  bool _showGo = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _ritualDuration);
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _scale = Tween<double>(
      begin: 0.7,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    WidgetsBinding.instance.addPostFrameCallback((_) => _runCountdown());
  }

  Future<void> _runCountdown() async {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    for (final count in [3, 2, 1]) {
      if (!mounted) return;
      setState(() {
        _count = count;
        _showGo = false;
      });

      if (reduceMotion) {
        await Future<void>.delayed(const Duration(milliseconds: 1000));
      } else {
        await _controller.forward(from: 0);
        if (!mounted) return;
        await Future<void>.delayed(_holdDuration);
      }

      if (!mounted) return;
    }

    if (!mounted) return;
    setState(() => _showGo = true);
    await Future<void>.delayed(_goDuration);
    if (!mounted) return;

    widget.onCountdownComplete();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pulseTheme = Theme.of(context).extension<PulseCoachTheme>()!;
    final l10n = AppLocalizations.of(context)!;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final semanticLabel = _showGo
        ? l10n.countdownGoAnnounce
        : l10n.countdownSemanticAnnounce(_count.toString());

    final numberWidget = Text(
      _showGo ? 'GO' : '$_count',
      style: AppTextStyles.countdown.copyWith(color: Colors.white),
    );
    final animated = AnimatedBuilder(
      animation: _controller,
      builder: (_, child) => Opacity(
        opacity: _opacity.value,
        child: Transform.scale(scale: _scale.value, child: child),
      ),
      child: numberWidget,
    );

    final countdownNumber = Semantics(
      liveRegion: true,
      label: semanticLabel,
      child: ExcludeSemantics(child: reduceMotion ? numberWidget : animated),
    );

    return Scaffold(
      backgroundColor: pulseTheme.primaryColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              countdownNumber,
              if (widget.sessionTitle != null) ...[
                  const SizedBox(height: 16),
                  Text(
                  widget.sessionTitle!,
                  style: AppTextStyles.body.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
