import 'dart:convert';
import 'package:exercise_form_frontend/core/app_preferences.dart';

class LatestAnalysisStore {
  LatestAnalysisStore._();

  static Map<String, dynamic>? _latestResult;
  static Map<String, dynamic>? _latestVisualResult;

  static Map<String, dynamic>? get latestResult => _latestResult;
  static Map<String, dynamic>? get latestVisualResult => _latestVisualResult;

  static void save(Map<String, dynamic> result) {
    _latestResult = result;
    final encoded = jsonEncode(result);
    AppPreferences.prefs.setString('latest_analysis', encoded);
  }

  static void saveVisual(Map<String, dynamic> result) {
    _latestVisualResult = result;
    final encoded = jsonEncode(result);
    AppPreferences.prefs.setString('latest_visual_analysis', encoded);
  }

  static void load() {
    final raw = AppPreferences.prefs.getString('latest_analysis');
    if (raw != null) {
      try {
        _latestResult = jsonDecode(raw);
      } catch (_) {}
    }
    final rawVisual = AppPreferences.prefs.getString('latest_visual_analysis');
    if (rawVisual != null) {
      try {
        _latestVisualResult = jsonDecode(rawVisual);
      } catch (_) {}
    }
  }

  static void clear() {
    _latestResult = null;
    _latestVisualResult = null;
    AppPreferences.prefs.remove('latest_analysis');
    AppPreferences.prefs.remove('latest_visual_analysis');
  }
}
