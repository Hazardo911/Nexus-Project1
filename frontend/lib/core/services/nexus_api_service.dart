import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

class NexusApiService {
  NexusApiService._();

  static const String baseUrl = 'http://127.0.0.1:8000';
  static const String defaultUserId = 'demo_user';

  static Future<Map<String, dynamic>> analyzeUploadedVideo({
    required String videoPath,
    required String selectedExercise,
    String mode = 'fitness',
    String userId = defaultUserId,
    String injury = 'ACL',
    String stage = 'early',
    int fps = 30,
    double windowSeconds = 3.33,
  }) async {
    final mappedExercise = _mapExercise(selectedExercise) ?? selectedExercise;
    final file = File(videoPath);
    if (!await file.exists()) {
      throw const NexusApiException(statusCode: 0, message: 'Selected video file could not be found.');
    }

    final boundary = '----nexus-${DateTime.now().millisecondsSinceEpoch}';
    final client = HttpClient();
    try {
      final request = await client.postUrl(Uri.parse('$baseUrl/demo/analyze-video'));
      request.headers.set(HttpHeaders.contentTypeHeader, 'multipart/form-data; boundary=$boundary');
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');

      void writeField(String name, String value) {
        request.write('--$boundary\r\n');
        request.write('Content-Disposition: form-data; name="$name"\r\n\r\n');
        request.write('$value\r\n');
      }

      writeField('mode', mode);
      writeField('user_id', userId);
      writeField('selected_exercise', mappedExercise);
      writeField('injury', injury);
      writeField('stage', stage);
      writeField('fps', '$fps');
      writeField('window_seconds', '$windowSeconds');
      writeField('include_visuals', 'false');

      final filename = videoPath.split(Platform.pathSeparator).last;
      request.write('--$boundary\r\n');
      request.write('Content-Disposition: form-data; name="file"; filename="$filename"\r\n');
      request.write('Content-Type: video/mp4\r\n\r\n');
      await request.addStream(file.openRead());
      request.write('\r\n--$boundary--\r\n');

      final response = await request.close().timeout(const Duration(minutes: 2));
      final responseBody = await response.transform(utf8.decoder).join().timeout(const Duration(minutes: 2));
      final decoded = responseBody.isEmpty ? <String, dynamic>{} : await compute(_decodeAndTrimApiMap, responseBody);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded;
      }
      throw NexusApiException(
        statusCode: response.statusCode,
        message: decoded['detail']?.toString() ?? decoded['message']?.toString() ?? 'Video analysis failed',
      );
    } on SocketException {
      throw const NexusApiException(
        statusCode: 0,
        message: 'Backend not reachable. Start the new FastAPI backend and use adb reverse tcp:8000 tcp:8000.',
      );
    } finally {
      client.close(force: true);
    }
  }

  static Future<Map<String, dynamic>> getSummary({String userId = defaultUserId}) async {
    final encodedUserId = Uri.encodeQueryComponent(userId);
    return _request('GET', '/summary/?user_id=$encodedUserId');
  }

  static Future<Map<String, dynamic>> getLatestResult({String userId = defaultUserId}) async {
    final encodedUserId = Uri.encodeQueryComponent(userId);
    return _request('GET', '/latest-result/?user_id=$encodedUserId');
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
  }) async {
    final client = HttpClient();
    try {
      final request = await client.openUrl(method, Uri.parse('$baseUrl$path'));
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (body != null) {
        request.write(jsonEncode(body));
      }
      final response = await request.close().timeout(const Duration(seconds: 30));
      final responseBody = await response.transform(utf8.decoder).join().timeout(const Duration(seconds: 30));
      final decoded = responseBody.isEmpty ? <String, dynamic>{} : await compute(_decodeAndTrimApiMap, responseBody);
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
        message: 'Backend not reachable. Start the new FastAPI backend and use adb reverse tcp:8000 tcp:8000.',
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

Map<String, dynamic> _decodeAndTrimApiMap(String responseBody) {
  final decoded = jsonDecode(responseBody);
  if (decoded is! Map) {
    return <String, dynamic>{};
  }
  return _trimHeavyPayload(Map<String, dynamic>.from(decoded));
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
