// =============================================================================
// StorageService
// Thin wrapper around shared_preferences for offline persistence.
// We keep all key names in one place to avoid typos and make migrations easy.
// =============================================================================

import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  // Storage keys — change these if you ever need a data reset across versions.
  static const String _highScoreKey = 'neon_drift_high_score';
  static const String _bestLevelKey = 'neon_drift_best_level';
  static const String _gamesPlayedKey = 'neon_drift_games_played';

  // -------- High score --------

  /// Returns the best score the player has ever achieved (0 if first run).
  Future<int> getHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_highScoreKey) ?? 0;
  }

  /// Saves [score] only if it's greater than the current high score.
  Future<bool> saveHighScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_highScoreKey) ?? 0;
    if (score > current) {
      await prefs.setInt(_highScoreKey, score);
      return true; // new high score
    }
    return false;
  }

  // -------- Best level --------

  Future<int> getBestLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_bestLevelKey) ?? 1;
  }

  Future<void> saveBestLevel(int level) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_bestLevelKey) ?? 1;
    if (level > current) {
      await prefs.setInt(_bestLevelKey, level);
    }
  }

  // -------- Games played counter --------

  Future<int> getGamesPlayed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_gamesPlayedKey) ?? 0;
  }

  Future<void> incrementGamesPlayed() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_gamesPlayedKey) ?? 0;
    await prefs.setInt(_gamesPlayedKey, current + 1);
  }

  // -------- Utility --------

  /// Reset all saved game data. Wire this to a "Clear stats" button in a
  /// future settings screen.
  Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_highScoreKey);
    await prefs.remove(_bestLevelKey);
    await prefs.remove(_gamesPlayedKey);
  }
}
