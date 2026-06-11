import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  static const String defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );

  static const String _tokenKey = 'pm_api_token';

  String baseUrl = defaultBaseUrl;
  String? _token;

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
  }

  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<String?> getToken() async {
    if (_token == null) {
      await loadToken();
    }
    return _token;
  }

  Future<dynamic> get(String path, {Map<String, String?> query = const {}}) {
    return _request('GET', path, query: query);
  }

  Future<dynamic> post(String path, {Object? body}) {
    return _request('POST', path, body: body);
  }

  Future<dynamic> put(String path, {Object? body}) {
    return _request('PUT', path, body: body);
  }

  Future<dynamic> patch(String path, {Object? body}) {
    return _request('PATCH', path, body: body);
  }

  Future<dynamic> delete(String path) {
    return _request('DELETE', path);
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, String?> query = const {},
    Object? body,
  }) async {
    if (_token == null) {
      await loadToken();
    }

    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: {
        for (final entry in query.entries)
          if (entry.value != null && entry.value!.isNotEmpty)
            entry.key: entry.value!,
      },
    );

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };

    final encodedBody = body == null ? null : jsonEncode(body);
    final response = switch (method) {
      'GET' => await http.get(uri, headers: headers),
      'POST' => await http.post(uri, headers: headers, body: encodedBody),
      'PUT' => await http.put(uri, headers: headers, body: encodedBody),
      'PATCH' => await http.patch(uri, headers: headers, body: encodedBody),
      'DELETE' => await http.delete(uri, headers: headers),
      _ => throw UnsupportedError('Unsupported method $method'),
    };

    final text = utf8.decode(response.bodyBytes);
    final decoded = text.isEmpty ? null : jsonDecode(text);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['message']?.toString() ?? 'API request failed'
          : 'API request failed';
      throw ApiException(response.statusCode, message);
    }

    return decoded;
  }
}

final apiClient = ApiClient.instance;
