import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NexusApiService {
  NexusApiService._();

  static const String baseUrl = 'http://10.0.2.2:8000';
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
    final authToken = await token;
    final uid = await userId;
    
    // Add user_id to query params if not in body
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: {
        ...Uri.parse('$baseUrl$path').queryParameters,
        if (uid != null) 'user_id': uid,
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

