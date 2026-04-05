import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NexusApiService {
  NexusApiService._();

  static const String baseUrl = 'http://10.0.2.2:8000';
  static const String defaultUserId = 'demo_user';
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'access_token';
  static const _userIdKey = 'user_id';
  static const _userNameKey = 'user_name';

  static Future<String?> get token => _storage.read(key: _tokenKey);
  static Future<String?> get userId => _storage.read(key: _userIdKey);
  static Future<String?> get userName => _storage.read(key: _userNameKey);

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final body = {'email': email, 'password': password};
    final response = await _request('POST', '/login', body: body);
    await _saveAuthData(response);
    return response;
  }

  static Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final body = {'name': name, 'email': email, 'password': password};
    final response = await _request('POST', '/register', body: body);
    await _saveAuthData(response);
    return response;
  }

  static Future<void> logout() async {
    await _storage.deleteAll();
  }

  static Future<void> _saveAuthData(Map<String, dynamic> data) async {
    await _storage.write(key: _tokenKey, value: data['access_token']);
    await _storage.write(key: _userIdKey, value: data['user_id']);
    await _storage.write(key: _userNameKey, value: data['name']);
  }

  static Future<Map<String, dynamic>> startSession({String? exercise}) async {
    final uid = await userId;
    final body = <String, dynamic>{'user_id': uid ?? 'anonymous'};
    final mappedExercise = _mapExercise(exercise);
    if (mappedExercise != null) {
      body['exercise'] = mappedExercise;
    }
    return _request('POST', '/start', body: body);
  }

  static Future<Map<String, dynamic>> analyzeUploadedVideo({
    required String videoPath,
    required String selectedExercise,
    String mode = 'fitness',
    String? userId,
    String injury = 'ACL',
    String stage = 'early',
    int fps = 30,
    double windowSeconds = 3.33,
    bool includeVisuals = false,
  }) async {
    final uid = userId ?? await NexusApiService.userId ?? defaultUserId;
    final mappedExercise = _mapExercise(selectedExercise) ?? selectedExercise;
    final file = File(videoPath);
    if (!await file.exists()) {
      throw const NexusApiException(statusCode: 0, message: 'Selected video file could not be found.');
    }

    final boundary = '----nexus-${DateTime.now().millisecondsSinceEpoch}';
    final client = HttpClient();
    final authToken = await token;

    try {
      final request = await client.postUrl(Uri.parse('$baseUrl/demo/analyze-video'));
      request.headers.set(HttpHeaders.contentTypeHeader, 'multipart/form-data; boundary=$boundary');
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (authToken != null) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $authToken');
      }

      void writeField(String name, String value) {
        request.write('--$boundary\r\n');
        request.write('Content-Disposition: form-data; name="$name"\r\n\r\n');
        request.write('$value\r\n');
      }

      writeField('mode', mode);
      writeField('user_id', uid);
      writeField('selected_exercise', mappedExercise);
      writeField('injury', injury);
      writeField('stage', stage);
      writeField('fps', '$fps');
      writeField('window_seconds', '$windowSeconds');
      writeField('include_visuals', includeVisuals ? 'true' : 'false');

      final filename = videoPath.split(Platform.pathSeparator).last;
      request.write('--$boundary\r\n');
      request.write('Content-Disposition: form-data; name="file"; filename="$filename"\r\n');
      request.write('Content-Type: video/mp4\r\n\r\n');
      await request.addStream(file.openRead());
      request.write('\r\n--$boundary--\r\n');

      final response = await request.close().timeout(const Duration(minutes: 2));
      final responseBody = await response.transform(utf8.decoder).join().timeout(const Duration(minutes: 2));
      final decoded = responseBody.isEmpty
          ? <String, dynamic>{}
          : includeVisuals
              ? await compute(_decodeApiMap, responseBody)
              : await compute(_decodeAndTrimApiMap, responseBody);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _attachSummary(<String, dynamic>{...decoded, 'mode': mode}, uid);
      }
      throw NexusApiException(
        statusCode: response.statusCode,
        message: decoded['detail']?.toString() ?? decoded['message']?.toString() ?? 'Video analysis failed',
      );
    } on SocketException {
      throw const NexusApiException(
        statusCode: 0,
        message: 'Backend not reachable. Start the FastAPI server and use adb reverse tcp:8000 tcp:8000.',
      );
    } finally {
      client.close(force: true);
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

  static Future<Map<String, dynamic>> getSummary({String? userId}) async {
    final uid = userId ?? await NexusApiService.userId ?? defaultUserId;
    return _request('GET', '/summary/', queryParams: {'user_id': uid});
  }

  static Future<Map<String, dynamic>> getLatestResult({String? userId}) async {
    final uid = userId ?? await NexusApiService.userId ?? defaultUserId;
    return _request('GET', '/latest-result/', queryParams: {'user_id': uid}, preserveVisuals: true);
  }

  static Future<Map<String, dynamic>> getSessions({String? userId, int limit = 20}) async {
    final uid = userId ?? await NexusApiService.userId ?? defaultUserId;
    return _request('GET', '/sessions', queryParams: {'user_id': uid, 'limit': limit.toString()}, preserveVisuals: true);
  }

  static String? _mapExercise(String? exercise) {
    if (exercise == null || exercise.isEmpty) return null;
    switch (exercise.toLowerCase()) {
      case 'squat':
        return 'BodyWeightSquats';
      case 'lunge':
      case 'lunges':
        return 'Lunges';
      case 'press':
        return 'BenchPress';
      case 'deadlift':
        return 'CleanAndJerk';
      default:
        return exercise;
    }
  }

  static Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    bool preserveVisuals = false,
  }) async {
    final client = HttpClient();
    final authToken = await token;
    final uid = await userId;
    
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: {
        ...Uri.parse('$baseUrl$path').queryParameters,
        if (uid != null) 'user_id': uid,
        if (queryParams != null) ...queryParams,
      },
    );

    try {
      final request = await client.openUrl(method, uri);
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (authToken != null) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $authToken');
      }
      if (body != null) {
        request.write(jsonEncode(body));
      }
      final response = await request.close().timeout(const Duration(seconds: 30));
      final responseBody = await response.transform(utf8.decoder).join().timeout(const Duration(seconds: 30));
      final decoded = responseBody.isEmpty
          ? <String, dynamic>{}
          : preserveVisuals
              ? await compute(_decodeApiMap, responseBody)
              : await compute(_decodeAndTrimApiMap, responseBody);
      
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

  static Future<Map<String, dynamic>> _attachSummary(Map<String, dynamic> source, String userId) async {
    try {
      final summary = await getSummary(userId: userId);
      return <String, dynamic>{
        ...source,
        if (summary['weekly_summary'] != null) 'weekly_summary': summary['weekly_summary'],
        if (summary['monthly_summary'] != null) 'monthly_summary': summary['monthly_summary'],
        if (summary['safe_session_rate'] != null && source['score'] == null) 'safe_session_rate': summary['safe_session_rate'],
      };
    } catch (_) {
      return source;
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

Map<String, dynamic> _decodeAndTrimApiMap(String responseBody) {
  final decoded = jsonDecode(responseBody);
  if (decoded is! Map) {
    return <String, dynamic>{};
  }
  return _trimHeavyPayload(Map<String, dynamic>.from(decoded));
}

Map<String, dynamic> _decodeApiMap(String responseBody) {
  final decoded = jsonDecode(responseBody);
  if (decoded is! Map) {
    return <String, dynamic>{};
  }
  return Map<String, dynamic>.from(decoded);
}

Map<String, dynamic> _trimHeavyPayload(Map<String, dynamic> source) {
  source.remove('landmarks');
  source.remove('connections');

  for (final entry in source.entries.toList()) {
    final value = entry.value;
    if (value is Map) {
      source[entry.key] = _trimHeavyPayload(Map<String, dynamic>.from(value));
      continue;
    }
    if (value is List && value.length > 100) {
      source[entry.key] = '${value.length} items';
    }
  }

  return source;
}
