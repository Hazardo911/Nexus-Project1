class LatestAnalysisStore {
  LatestAnalysisStore._();

  static Map<String, dynamic>? _latestResult;

  static Map<String, dynamic>? get latestResult => _latestResult;

  static bool get hasResult => _latestResult != null && _latestResult!.isNotEmpty;

  static void save(Map<String, dynamic> result) {
    _latestResult = Map<String, dynamic>.from(result);
  }

  static void clear() {
    _latestResult = null;
  }
}
