import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('it'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'PulseCoach'**
  String get appTitle;

  /// No description provided for @stateLabelActive.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get stateLabelActive;

  /// No description provided for @stateLabelFatigued.
  ///
  /// In en, this message translates to:
  /// **'Under load'**
  String get stateLabelFatigued;

  /// No description provided for @stateLabelAtRisk.
  ///
  /// In en, this message translates to:
  /// **'At risk'**
  String get stateLabelAtRisk;

  /// No description provided for @stateLabelRecovering.
  ///
  /// In en, this message translates to:
  /// **'Recovering'**
  String get stateLabelRecovering;

  /// No description provided for @staticCopyActive.
  ///
  /// In en, this message translates to:
  /// **'Ready for today\'s plan.'**
  String get staticCopyActive;

  /// No description provided for @staticCopyFatigued.
  ///
  /// In en, this message translates to:
  /// **'Today we lighten the load to recover.'**
  String get staticCopyFatigued;

  /// No description provided for @staticCopyAtRisk.
  ///
  /// In en, this message translates to:
  /// **'Let\'s restart gently. Short, easy sessions.'**
  String get staticCopyAtRisk;

  /// No description provided for @staticCopyRecovering.
  ///
  /// In en, this message translates to:
  /// **'Let\'s build the rhythm, one step at a time.'**
  String get staticCopyRecovering;

  /// No description provided for @transitionActiveAtRisk.
  ///
  /// In en, this message translates to:
  /// **'We missed you. Let\'s restart light - 5 minutes is enough today.'**
  String get transitionActiveAtRisk;

  /// No description provided for @transitionActiveFatigued.
  ///
  /// In en, this message translates to:
  /// **'You pushed hard. Today we lighten up: short session.'**
  String get transitionActiveFatigued;

  /// No description provided for @transitionFatiguedAtRisk.
  ///
  /// In en, this message translates to:
  /// **'Your body is asking for a longer pause. Let\'s resume gently.'**
  String get transitionFatiguedAtRisk;

  /// No description provided for @transitionRecoveringFatigued.
  ///
  /// In en, this message translates to:
  /// **'We are getting back, but the last effort was intense. Let\'s return to an easy session.'**
  String get transitionRecoveringFatigued;

  /// No description provided for @transitionAtRiskRecovering.
  ///
  /// In en, this message translates to:
  /// **'You are getting back into rhythm. Let\'s keep it calm.'**
  String get transitionAtRiskRecovering;

  /// No description provided for @transitionFatiguedRecovering.
  ///
  /// In en, this message translates to:
  /// **'You are getting back into rhythm. Let\'s keep it calm.'**
  String get transitionFatiguedRecovering;

  /// No description provided for @transitionRecoveringActive.
  ///
  /// In en, this message translates to:
  /// **'You are back in shape! Let\'s resume the full plan.'**
  String get transitionRecoveringActive;

  /// No description provided for @comingUpHeader.
  ///
  /// In en, this message translates to:
  /// **'COMING UP'**
  String get comingUpHeader;

  /// No description provided for @errorLoadingPlan.
  ///
  /// In en, this message translates to:
  /// **'Unable to load the plan.'**
  String get errorLoadingPlan;

  /// No description provided for @allDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Great work!'**
  String get allDoneTitle;

  /// No description provided for @allDoneBody.
  ///
  /// In en, this message translates to:
  /// **'All sessions are complete for today.'**
  String get allDoneBody;

  /// No description provided for @heroCardSemanticPreamble.
  ///
  /// In en, this message translates to:
  /// **'Next session: {displayName}, {durationLabel}'**
  String heroCardSemanticPreamble(String displayName, String durationLabel);

  /// No description provided for @heroCardSemanticCta.
  ///
  /// In en, this message translates to:
  /// **'Tap to start.'**
  String get heroCardSemanticCta;

  /// No description provided for @regenSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'Regenerate workout plan'**
  String get regenSemanticLabel;

  /// No description provided for @regenTooltip.
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get regenTooltip;

  /// No description provided for @startSessionButton.
  ///
  /// In en, this message translates to:
  /// **'Start session'**
  String get startSessionButton;

  /// No description provided for @completedCardSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed: {displayName}, {durationLabel}.'**
  String completedCardSemanticLabel(String displayName, String durationLabel);

  /// No description provided for @compactCardSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'Next session: {displayName}, {durationLabel}. Tap to select as the next session.'**
  String compactCardSemanticLabel(String displayName, String durationLabel);

  /// No description provided for @completionRingSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'Daily progress: {completed} of {total} sessions completed'**
  String completionRingSemanticLabel(String completed, String total);

  /// No description provided for @sessionNameMobility.
  ///
  /// In en, this message translates to:
  /// **'Mobility'**
  String get sessionNameMobility;

  /// No description provided for @sessionNameCardio.
  ///
  /// In en, this message translates to:
  /// **'Cardio'**
  String get sessionNameCardio;

  /// No description provided for @sessionNameBreathing.
  ///
  /// In en, this message translates to:
  /// **'Breathing'**
  String get sessionNameBreathing;

  /// No description provided for @intensityLow.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get intensityLow;

  /// No description provided for @intensityMedium.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get intensityMedium;

  /// No description provided for @intensityHigh.
  ///
  /// In en, this message translates to:
  /// **'Intense'**
  String get intensityHigh;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
