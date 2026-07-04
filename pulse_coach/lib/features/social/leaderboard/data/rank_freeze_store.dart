import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the viewer's pinned rank across app restarts for the
/// duration of a protective-state (AtRisk/Recovering) episode.
/// Cleared the first time the viewer is observed back in Active/Fatigued.
@injectable
class RankFreezeStore {
  static const String _key = 'leaderboard_frozen_rank';

  final SharedPreferences _prefs;
  const RankFreezeStore(this._prefs);

  int? getFrozenRank() => _prefs.getInt(_key);

  Future<void> setFrozenRank(int rank) => _prefs.setInt(_key, rank);

  Future<void> clear() => _prefs.remove(_key);
}
