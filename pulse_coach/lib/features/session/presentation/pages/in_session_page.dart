import 'package:flutter/material.dart';
import 'package:pulse_coach/core/theme/app_text_styles.dart';
import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';
import 'package:pulse_coach/features/session/presentation/widgets/countdown_overlay.dart';
import 'package:pulse_coach/features/today/presentation/widgets/session_card_helpers.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

class InSessionPage extends StatefulWidget {
  final PlannedSession? session;

  const InSessionPage({this.session, super.key});

  @override
  State<InSessionPage> createState() => _InSessionPageState();
}

class _InSessionPageState extends State<InSessionPage> {
  bool _countdownDone = false;

  @override
  Widget build(BuildContext context) {
    if (!_countdownDone) {
      final l10n = AppLocalizations.of(context)!;
      final sessionTitle = widget.session != null
          ? sessionDisplayName(widget.session!.sessionType, l10n)
          : null;

      return CountdownOverlay(
        sessionTitle: sessionTitle,
        onCountdownComplete: () {
          if (mounted) setState(() => _countdownDone = true);
        },
      );
    }

    final pulseTheme = Theme.of(context).extension<PulseCoachTheme>()!;
    return Scaffold(
      backgroundColor: pulseTheme.surface,
      body: const Center(
        child: Text('In Session — Story 8.2', style: AppTextStyles.body),
      ),
    );
  }
}
