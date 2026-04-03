class LatestAnalysisStore {
  LatestAnalysisStore._();

  static Map<String, dynamic>? _latestResult;
  static Map<String, dynamic>? _latestVisualResult;

  static Map<String, dynamic>? get latestResult => _latestResult;
  static Map<String, dynamic>? get latestVisualResult => _latestVisualResult;

  static bool get hasResult => _latestResult != null && _latestResult!.isNotEmpty;
  static bool get hasVisualResult => _latestVisualResult != null && _latestVisualResult!.isNotEmpty;

  static void save(Map<String, dynamic> result) {
    _latestResult = Map<String, dynamic>.from(result);
  }

  static void saveVisual(Map<String, dynamic> result) {
    _latestVisualResult = Map<String, dynamic>.from(result);
  }

  static void clear() {
    _latestResult = null;
    _latestVisualResult = null;
  }
}
