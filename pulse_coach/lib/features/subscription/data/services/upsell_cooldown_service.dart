import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@singleton
class UpsellCooldownService {
  static const _kCooldownKey = 'pro_upsell_dismissed_date';
  final SharedPreferences _prefs;

  UpsellCooldownService(this._prefs);

  bool isCoolingDown() {
    final stored = _prefs.getString(_kCooldownKey);
    if (stored == null) return false;
    return stored == _todayLocalString();
  }

  void recordDismissal() {
    _prefs.setString(_kCooldownKey, _todayLocalString());
  }

  String _todayLocalString() =>
      DateTime.now().toLocal().toIso8601String().substring(0, 10);
}
