import 'dart:convert';
import 'dart:io';

class NexusApiService {
  NexusApiService._();

  static const String baseUrl = 'http://127.0.0.1:8000';

  static Future<Map<String, dynamic>> startSession({String? exercise}) async {
    final body = <String, dynamic>{};
    final mappedExercise = _mapExercise(exercise);
    if (mappedExercise != null) {
      body['exercise'] = mappedExercise;
    }
    return _request('POST', '/start', body: body.isEmpty ? null : body);
  }

  static String? _mapExercise(String? exercise) {
    if (exercise == null || exercise.isEmpty) return null;
    switch (exercise.toLowerCase()) {
      case 'squat':
        return 'squat';
      case 'lunge':
      case 'lunges':
        return 'lunges';
      case 'press':
      case 'benchpress':
      case 'bench press':
        return 'benchpress';
      case 'deadlift':
        return null;
      default:
        return exercise.toLowerCase();
    }
  }

  static Future<Map<String, dynamic>> stopSession() async {
    return _request('POST', '/stop');
  }

  static Future<Map<String, dynamic>> resetSession() async {
    return _request('POST', '/session/reset');
  }

  static Future<Map<String, dynamic>> getStatus() async {
    return _request('GET', '/status');
  }

  static Future<Map<String, dynamic>> getSession() async {
    return _request('GET', '/session');
  }

  static Future<Map<String, dynamic>> getSummary() async {
    return _request('GET', '/summary');
  }

  static Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final client = HttpClient();
    try {
      final request = await client.openUrl(method, Uri.parse('$baseUrl$path'));
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (body != null) {
        request.write(jsonEncode(body));
      }
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      final decoded = responseBody.isEmpty ? <String, dynamic>{} : jsonDecode(responseBody) as Map<String, dynamic>;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded;
      }
      throw NexusApiException(
        statusCode: response.statusCode,
        message: decoded['detail']?.toString() ?? decoded['message']?.toString() ?? 'Request failed',
      );
    } on SocketException {
      throw const NexusApiException(
        statusCode: 0,
        message: 'Backend not reachable. Start FastAPI and use adb reverse tcp:8000 tcp:8000.',
      );
    } finally {
      client.close(force: true);
    }
  }
}

class NexusApiException implements Exception {
  const NexusApiException({required this.statusCode, required this.message});

  final int statusCode;
  final String message;

  @override
  String toString() => message;
}

