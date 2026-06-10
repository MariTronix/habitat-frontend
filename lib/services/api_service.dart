import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  ApiService({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? _defaultBaseUrl;

  final http.Client _client;
  final String _baseUrl;
  String? _token;

  static String get _defaultBaseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) return envUrl;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }

    return 'http://127.0.0.1:8080';
  }

  String? get token => _token;

  void setToken(String token) {
    _token = token;
  }

  void clearToken() {
    _token = null;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await post('/auth/login', {
      'email': email,
      'password': password,
    });

    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _extractErrorMessage(response),
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final token = data['token'] as String?;
    if (token != null && token.isNotEmpty) {
      setToken(token);
    }
    return data;
  }

  Future<http.Response> get(String endpoint, {Map<String, String>? query}) {
    return _client.get(_uri(endpoint, query), headers: _headers());
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) {
    return _client.post(
      _uri(endpoint),
      headers: _headers(),
      body: jsonEncode(body),
    );
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body) {
    return _client.put(
      _uri(endpoint),
      headers: _headers(),
      body: jsonEncode(body),
    );
  }

  Future<http.Response> patch(String endpoint, {Map<String, dynamic>? body, Map<String, String>? query}) {
    return _client.patch(
      _uri(endpoint, query),
      headers: _headers(),
      body: body == null ? null : jsonEncode(body),
    );
  }

  Future<http.Response> delete(String endpoint) {
    return _client.delete(_uri(endpoint), headers: _headers());
  }

  Uri _uri(String endpoint, [Map<String, String>? query]) {
    final normalizedEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final uri = Uri.parse('$_baseUrl$normalizedEndpoint');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: query);
  }

  Map<String, String> _headers() {
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  String _extractErrorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded['message']?.toString() ??
            decoded['error']?.toString() ??
            'Erro ${response.statusCode} ao comunicar com o servidor.';
      }
    } catch (_) {
      
    }

    return response.body.isNotEmpty
        ? response.body
        : 'Erro ${response.statusCode} ao comunicar com o servidor.';
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => message;
}
