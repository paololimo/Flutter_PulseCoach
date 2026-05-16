// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'PulseCoach';

  @override
  String get stateLabelActive => 'In forma';

  @override
  String get stateLabelFatigued => 'Sotto sforzo';

  @override
  String get stateLabelAtRisk => 'In ripresa';

  @override
  String get stateLabelRecovering => 'In recupero';

  @override
  String get staticCopyActive => 'Pronto per il piano di oggi.';

  @override
  String get staticCopyFatigued => 'Oggi alleggeriamo per recuperare.';

  @override
  String get staticCopyAtRisk =>
      'Ripartiamo con calma. Sessioni brevi e leggere.';

  @override
  String get staticCopyRecovering =>
      'Costruiamo il ritmo, un passo alla volta.';

  @override
  String get transitionActiveAtRisk =>
      'Ci sei mancato. Ripartiamo leggeri — 5 minuti bastano oggi.';

  @override
  String get transitionActiveFatigued =>
      'Hai spinto forte. Oggi alleggeriamo: sessione corta.';

  @override
  String get transitionFatiguedAtRisk =>
      'Il corpo chiede una pausa più lunga. Riprendiamo dolcemente.';

  @override
  String get transitionRecoveringFatigued =>
      'Stiamo rientrando, ma l\'ultimo sforzo è stato intenso. Torniamo a una sessione facile.';

  @override
  String get transitionAtRiskRecovering =>
      'Stai tornando in ritmo. Continuiamo con calma.';

  @override
  String get transitionFatiguedRecovering =>
      'Stai tornando in ritmo. Continuiamo con calma.';

  @override
  String get transitionRecoveringActive =>
      'Sei di nuovo in forma! Riprendiamoci il piano completo.';

  @override
  String get comingUpHeader => 'PROSSIME';

  @override
  String get errorLoadingPlan => 'Impossibile caricare il piano.';

  @override
  String get allDoneTitle => 'Ottimo lavoro!';

  @override
  String get allDoneBody => 'Tutte le sessioni completate per oggi.';

  @override
  String heroCardSemanticPreamble(String displayName, String durationLabel) {
    return 'Prossima sessione: $displayName, $durationLabel';
  }

  @override
  String get heroCardSemanticCta => 'Tocca per iniziare.';

  @override
  String get regenSemanticLabel => 'Rigenera il piano allenamento';

  @override
  String get regenTooltip => 'Rigenera';

  @override
  String get startSessionButton => 'Inizia sessione';

  @override
  String completedCardSemanticLabel(String displayName, String durationLabel) {
    return 'Completata: $displayName, $durationLabel.';
  }

  @override
  String compactCardSemanticLabel(String displayName, String durationLabel) {
    return 'Sessione successiva: $displayName, $durationLabel. Tocca per selezionare come prossima sessione.';
  }

  @override
  String completionRingSemanticLabel(String completed, String total) {
    return 'Progressione giornaliera: $completed di $total sessioni completate';
  }

  @override
  String get sessionNameMobility => 'Mobilità';

  @override
  String get sessionNameCardio => 'Cardio';

  @override
  String get sessionNameBreathing => 'Respirazione';

  @override
  String get intensityLow => 'Leggera';

  @override
  String get intensityMedium => 'Moderata';

  @override
  String get intensityHigh => 'Intensa';
}
