import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static String get productionBaseUrl => dotenv.env['API_URL'] ?? 'http://localhost:8080';
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

    return productionBaseUrl;
  }

  String? get token => _token;
  String get baseUrl => _baseUrl;

  void setToken(String token) {
    _token = token;
  }

  void clearToken() {
    _token = null;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    print('📡 [API] POST /auth/login - email: $email');
    final response = await post('/auth/login', {
      'email': email,
      'password': password,
    });

    if (response.statusCode != 200) {
      print('❌ [API] Login falhou: ${response.statusCode}');
      throw ApiException(
        statusCode: response.statusCode,
        message: _extractErrorMessage(response),
      );
    }

    print('✅ [API] Login bem-sucedido: ${response.statusCode}');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final token = data['token'] as String?;
    if (token != null && token.isNotEmpty) {
      setToken(token);
      print('🔐 Token armazenado: ${token.substring(0, 20)}...');
    }
    return data;
  }

  Future<List<dynamic>> fetchUsers() async {
    print('📡 [API] GET /users');
    final response = await get('/users');

    if (response.statusCode != 200) {
      print('❌ [API] GET /users falhou: ${response.statusCode}');
      throw ApiException(
        statusCode: response.statusCode,
        message: _extractErrorMessage(response),
      );
    }

    print('✅ [API] GET /users sucesso: ${response.statusCode}');
    final data = jsonDecode(response.body);
    if (data is List) {
      print('✅ Retornou array direto com ${data.length} usuários');
      return data;
    }
    if (data is Map<String, dynamic> && data.containsKey('users')) {
      final users = data['users'];
      if (users is List) {
        return users;
      }
    }
    return [];
  }

  Future<http.Response> get(String endpoint, {Map<String, String>? query}) {
    return _send(() => _client.get(_uri(endpoint, query), headers: _headers()), endpoint);
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) {
    return _send(
      () => _client.post(
        _uri(endpoint),
        headers: _headers(),
        body: jsonEncode(body),
      ),
      endpoint,
    );
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body) {
    return _send(
      () => _client.put(
        _uri(endpoint),
        headers: _headers(),
        body: jsonEncode(body),
      ),
      endpoint,
    );
  }

  Future<http.Response> patch(String endpoint, {Map<String, dynamic>? body, Map<String, String>? query}) {
    return _send(
      () => _client.patch(
        _uri(endpoint, query),
        headers: _headers(),
        body: body == null ? null : jsonEncode(body),
      ),
      endpoint,
    );
  }

  Future<http.Response> delete(String endpoint) {
    return _send(() => _client.delete(_uri(endpoint), headers: _headers()), endpoint);
  }

  Future<http.Response> _send(Future<http.Response> Function() request, String endpoint) async {
    try {
      print('🌐 Conectando a: ${_uri(endpoint)}');
      final response = await request();
      print('📨 Resposta: ${response.statusCode}');
      return response;
    } catch (e) {
      print('❌ Erro de conexão: $e');
      throw ApiException(
        statusCode: 0,
        message: 'Não foi possível conectar ao backend em ${_uri(endpoint)}. Erro: $e',
      );
    }
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
    } catch (_) {}

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
